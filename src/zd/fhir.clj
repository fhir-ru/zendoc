(ns zd.fhir
  (:require [zd.core]
            [zd.methods :refer [annotation render-content render-block render-key inline-method]]
            [stylo.core :refer [c]]
            [zd.db]
            [clojure.string :as str]
            [clj-yaml.core]
            [cheshire.core]
            [zd.zen]
            [zen.core]))


(defmethod annotation :video
  [nm params]
  {:content :video})

(defn render-video [link]
  [:div {:class (c [:px 0] [:py 2] [:bg :white])}
   (if (or (str/starts-with? link "https://youtu.be")
           (str/starts-with? link "https://www.youtube.com"))
     [:iframe {:src (str "https://www.youtube.com/embed/" (last (str/split link #"/")))
               :width "560"
               :height "315"
               :frameborder 0
               :allow "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"}]
     
     [:div 
      [:video {:width "100%" :height "300px" :controls "controls"}
       [:source {:src link :type "video/mp4"}]]])])



(defmethod render-content :video
  [ztx {data :data}]
  (render-video data))



(defmethod render-key
  [:video]
  [_ {data :data}]
  (render-video data))

(defmethod render-key
  [:zd/debug]
  [_ {data :data :as block}]
  [:div 
   [:h3 "Debug page"]
   [:pre {:class (c :text-sm)}
    [:code {:class (str "language-json hljs")}
     (cheshire.core/generate-string
      (get-in block [:page]) {:pretty true})]]])

;; discussion
(defmethod inline-method :d
  [ztx m num]
  [:a {:href (str "https://github.com/fhir-ru/core/discussions/" num)
       :class (c [:text :blue-500] [:space-x 0.5])}
   [:i.fa.fa-comments-o {:class (name (c [:text :blue-400] :text-sm))}]
   [:span num]])

(defonce dtx (atom nil))

(defn stop-docs []
  (when-let [dtx @dtx] 
    (zd.core/stop dtx)))

(defn start-docs [opts]
  (stop-docs)
  (let [pth (str (System/getProperty "user.dir") "/docs")
        zrc (str (System/getProperty "user.dir") "/zrc")
        ztx (zen.core/new-context {:zd/paths [pth] :paths [pth zrc]})]
    (zen.core/read-ns ztx 'fhir.ru.core)
    (zd.core/start ztx (merge {:port 3030} opts))
    (reset! dtx ztx))
  :ok)


(defmethod annotation :zen/schema
  [nm params]
  {:content :zen/schema :zen/schema params})

(defmethod render-content :zen/schema
  [ztx {data :data}]
  (when data
    (println :reload data
             (zen.core/read-ns ztx (symbol (namespace data)))))
  (if-let [sch (zen.core/get-symbol ztx data)]
    [:div {:class (c :border [:p 0])}
     (zd.zen/render-schema sch)]
    [:pre (str "Could not find " data)]))

(defn -main [& [port reload :as args]]
  (println :args args)
  (start-docs {:production (not reload)
               :port (if port (Integer/parseInt port) 3333)}))

(comment

  (start-docs {:port 3333})

  (stop-docs)

  (do 
    (zen.core/read-ns @dtx 'fhir.ru.core)
    (zen.core/read-ns @dtx 'fhir.ru.core.organization)
    (zen.core/read-ns @dtx 'fhir.ru.diag.nosology)

    :ok)

  (zen.core/get-symbol @dtx 'fhir.ru.core.organization/Organization)
  (zen.core/get-symbol @dtx 'fhir.ru.diag.nosology/unit)

  (zen.core/errors @dtx)

  

  )
