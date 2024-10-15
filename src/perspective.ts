import * as THREE from "three";
import {
  cubeTextureLoader,
  gltfLoader,
  scene,
  tickSubscribers,
  setCamera,
  gui,
} from "./setup";
import vertexShaderToon from "./shaders/toon/vertex.glsl";
import fragmnetShaderToon from "./shaders/toon/fragment.glsl";

const envMap = cubeTextureLoader.load([
  "/envs/Cold_Sunset__Cam_2_Left+X.png",
  "/envs/Cold_Sunset__Cam_3_Right-X.png",
  "/envs/Cold_Sunset__Cam_4_Up+Y.png",
  "/envs/Cold_Sunset__Cam_5_Down-Y.png",
  "/envs/Cold_Sunset__Cam_0_Front+Z.png",
  "/envs/Cold_Sunset__Cam_1_Back-Z.png",
]);

const modelMaterial = new THREE.ShaderMaterial({
  uniforms: {
    uTime: new THREE.Uniform(0),
    uEnvironmentMap: new THREE.Uniform(envMap),
  },
  vertexShader: vertexShaderToon,
  fragmentShader: fragmnetShaderToon,
});

const model: {
  mesh: THREE.Group | null;
  rotate: boolean;
  isUsing: boolean;
} = {
  mesh: null,
  rotate: false,
  isUsing: false,
};

gltfLoader.load("/models/suzanne.glb", (gltf) => {
  gltf.scene.traverse((child) => {
    if (child instanceof THREE.Mesh) {
      child.material = modelMaterial;
    }
  });
  model.mesh = gltf.scene;
  if (model.isUsing) scene.add(model.mesh);
});

tickSubscribers.push((elapsedTime) => {
  modelMaterial.uniforms.uTime.value = elapsedTime;
  if (model.mesh) {
    model.mesh.rotation.y = model.rotate ? elapsedTime * 0.5 : 0;
  }
});

gui.add(model, "rotate").onChange((value: boolean) => {
  model.rotate = value;
});

export const initPerspective = () => {
  setCamera("perspective");
  if (model.mesh && !model.isUsing) scene.add(model.mesh);
  model.isUsing = true;
  scene.background = envMap;
  console.log("perspective");
};
