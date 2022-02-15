(ns zd.fhir
  (:require [zd.core]
            [zen.core]))

(defonce dtx (atom nil))

(defn stop-docs []
  (when-let [dtx @dtx] 
    (zd.core/stop dtx)))

(defn start-docs []
  (stop-docs)
  (let [pth (str (System/getProperty "user.dir") "/docs")
        ztx (zen.core/new-context {:zd/paths [pth] :paths [pth]})]
    (zd.core/start ztx {:port 3030})
    (reset! dtx ztx))
  :ok)

(comment


  (start-docs)

  (stop-docs)

  )
