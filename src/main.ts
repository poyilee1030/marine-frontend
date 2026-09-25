import L from "leaflet";
// Leaflet 的樣式；少了它，圖磚會錯位、縮放按鈕會跑版。
import "leaflet/dist/leaflet.css";

// SITL 預設起飛點：marlin-drone startup_sitl.sh 的 DEFAULT_LAT / DEFAULT_LON（新北）。
const HOME_LAT = 25.0226887;
const HOME_LNG = 121.4872364;

const map = L.map("map").setView([HOME_LAT, HOME_LNG], 17);

// OSM 公開圖磚（需要網路）。使用政策要求顯示 attribution，Leaflet 會畫在右下角。
L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
  maxZoom: 19,
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
}).addTo(map);
