(ns zd.fhir
  (:require [zd.core]
            [zen.core]))

(defonce dtx (atom nil))

(defn stop-docs []
  (when-let [dtx @dtx] 
    (zd.core/stop dtx)))

(defn start-docs [opts]
  (stop-docs)
  (let [pth (str (System/getProperty "user.dir") "/docs")
        ztx (zen.core/new-context {:zd/paths [pth] :paths [pth]})]
    (zd.core/start ztx (merge {:port 3030} opts))
    (reset! dtx ztx))
  :ok)


(defn -main [& [port reload]]
  (start-docs {:production (not reload)
               :port (if port (Integer/parseInt port) 3333)}))

(comment

  (start-docs {:port 3333})

  (stop-docs)

  )
