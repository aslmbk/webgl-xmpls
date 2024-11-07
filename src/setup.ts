import * as THREE from "three";
import { Timer } from "three/addons/misc/Timer.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/addons/loaders/DRACOLoader.js";
import { RGBELoader } from "three/addons/loaders/RGBELoader.js";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import GUI from "lil-gui";
import "./style.css";

const canvas = document.querySelector("#canvas") as HTMLCanvasElement;

const sizes = {
  width: window.innerWidth,
  height: window.innerHeight,
};
const parameters = {
  clearColor: 0x170024,
};

const gui = new GUI({ width: 340 });
gui.close();
gui.domElement.style.opacity = "0.2";
gui.onOpenClose((arg) => {
  gui.domElement.style.opacity = arg._closed ? "0.2" : "1";
});
const dracoLoader = new DRACOLoader();
dracoLoader.setDecoderPath("./draco/");
const gltfLoader = new GLTFLoader();
gltfLoader.setDRACOLoader(dracoLoader);
const textureLoader = new THREE.TextureLoader();
const cubeTextureLoader = new THREE.CubeTextureLoader();
const rgbeLoader = new RGBELoader();

const scene = new THREE.Scene();

const perspectiveCamera = new THREE.PerspectiveCamera(
  75,
  sizes.width / sizes.height,
  0.1,
  10000,
);
perspectiveCamera.position.set(0, 0, 3);
const controls = new OrbitControls(perspectiveCamera, canvas);
controls.enableDamping = true;
scene.add(perspectiveCamera);

const orthographicCamera = new THREE.OrthographicCamera(0, 1, 1, 0, 0.1, 100);
orthographicCamera.position.set(0, 0, 1);
scene.add(orthographicCamera);

let camera: THREE.Camera;
const setCamera = (type: "perspective" | "orthographic") => {
  if (type === "perspective") {
    camera = perspectiveCamera;
  } else {
    camera = orthographicCamera;
  }
};
setCamera("perspective");

const renderer = new THREE.WebGLRenderer({ canvas });
renderer.setSize(sizes.width, sizes.height);
renderer.setClearColor(parameters.clearColor);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.toneMapping = THREE.ACESFilmicToneMapping;

gui.addColor(parameters, "clearColor").onChange(() => {
  renderer.setClearColor(parameters.clearColor);
});

const resizeSubscribers: Array<(s: typeof sizes) => void> = [];

window.addEventListener("resize", () => {
  sizes.width = window.innerWidth;
  sizes.height = window.innerHeight;
  const aspectRatio = sizes.width / sizes.height;

  perspectiveCamera.aspect = aspectRatio;
  perspectiveCamera.updateProjectionMatrix();

  orthographicCamera.updateProjectionMatrix();

  renderer.setSize(sizes.width, sizes.height);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  resizeSubscribers.forEach((subscriber) => {
    subscriber(sizes);
  });
});

const tickSubscribers: Array<(elapsedTime: number, deltaTime: number) => void> =
  [];

const timer = new Timer();
const tick = () => {
  timer.update();
  const elapsedTime = timer.getElapsed();
  const deltaTime = timer.getDelta();

  tickSubscribers.forEach((subscriber) => {
    subscriber(elapsedTime, deltaTime);
  });

  controls.update();
  renderer.render(scene, camera);
  window.requestAnimationFrame(tick);
};

tick();

export {
  canvas,
  sizes,
  gui,
  gltfLoader,
  rgbeLoader,
  textureLoader,
  cubeTextureLoader,
  scene,
  camera,
  orthographicCamera,
  perspectiveCamera,
  renderer,
  resizeSubscribers,
  tickSubscribers,
  setCamera,
};
