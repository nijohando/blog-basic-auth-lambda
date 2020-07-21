(ns basic-auth)

(goog-define USERNAME "notset")
(goog-define PASSWORD "notset")

(def expected-auth-header-value
  (let [userpass (str USERNAME ":" PASSWORD)
        credentials (-> js/Buffer (.from userpass) (.toString "base64"))]
    (str "Basic " credentials)))

(def error-response {:status "401"
                     :statusDescription "Unauthorized"
                     :body "Unauthorized"
                     :bodyEncoding "text"
                     :headers {"www-authenticate" [{:key "WWW-Authenticate"
                                                    :value "Basic"}]}})
(defn- auth
  [event]
  (let [request (get-in event [:Records 0 :cf :request])
        actual-auth-header-value (get-in request [:headers :authorization 0 :value])]
    (if (= expected-auth-header-value actual-auth-header-value)
      request
      error-response)))

(defn handler [event _ callback]
  (->> (js->clj event :keywordize-keys true)
       (auth)
       (clj->js)
       (callback nil)))
