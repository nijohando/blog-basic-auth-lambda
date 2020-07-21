(ns basic-auth-test
  (:require
   [cljs.test :refer-macros [deftest is async]]
   [basic-auth :as auth]))

(deftest auth-ok
  (async done
    (let [cf {:cf
              {:request
               {:headers
                {:authorization [{:key "Authorization"
                                  :value (str "Basic " (-> js/Buffer
                                                         (.from "test_user:test_pass")
                                                         (.toString "base64")))}]}}}}
          event (clj->js {:Records [cf]})
          ctx #js {}
          callback (fn [error result]
                     (is (nil? error))
                     (is (= (get-in cf [:cf :request]) (js->clj result :keywordize-keys true)))
                     (done))]
            (basic-auth/handler event ctx callback))))


(deftest auth-ng-no-auth-header
  (async done
    (let [cf {:cf
              {:request
               {:headers {}}}}
          event (clj->js {:Records [cf]})
          ctx #js {}
          callback (fn [error result]
                     (let [r (js->clj result :keywordize-keys true)]
                       (is (nil? error))
                       (is (= (:status r) "401"))
                       (done)))]
            (basic-auth/handler event ctx callback))))

(deftest auth-ng-bad-credentails
  (async done
    (let [cf {:cf
              {:request
               {:headers
                {:authorization [{:key "Authorization"
                                  :value (str "Basic " (-> js/Buffer
                                                         (.from "bad_user:bad_pass")
                                                         (.toString "base64")))}]}}}}
          event (clj->js {:Records [cf]})
          ctx #js {}
          callback (fn [error result]
                     (let [r (js->clj result :keywordize-keys true)]
                       (is (nil? error))
                       (is (= (:status r) "401"))
                       (done)))]
            (basic-auth/handler event ctx callback))))
