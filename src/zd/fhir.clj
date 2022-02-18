(ns zd.fhir
  (:require [zd.core]
            [zd.methods :refer [annotation render-content render-block render-key inline-method]]
            [stylo.core :refer [c]]
            [zd.db]
            [clojure.string :as str]
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


;; discussion
(defmethod inline-method :d
  [ztx m num]
  [:a {:href (str "https://github.com/fhir-ru/core/discussions/" num)
       :class (c [:text :blue-500] :font-bold)}
   [:i.fa.fa-comments]
   (str " " num)])


(defmethod render-key
  [:title]
  [_ {title :data :as block}]
  [:h1 {:class (c [:mb 0] :border-b)}
   (when-let [img (get-in block [:page :resource :avatar])]
     [:img {:src img :class (c [:w 12] :inline-block [:mr 4] {:border-radius "100%"})}])
   title])

(defmethod render-key [:avatar] [_ block] [:div ])

(defmethod render-key [:menu-order] [_ block] [:div ])

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


(defn -main [& [port reload :as args]]
  (println :args args)
  (start-docs {:production (not reload)
               :port (if port (Integer/parseInt port) 3333)}))

(comment

  (start-docs {:port 3333})

  (stop-docs)

  )
