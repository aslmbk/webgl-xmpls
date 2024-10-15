import * as THREE from "three";
import {
  scene,
  setCamera,
  textureLoader,
  sizes,
  renderer,
  resizeSubscribers,
  tickSubscribers,
  perspectiveCamera,
} from "./setup";
import { TextureAtlas } from "./TextureAtlas.js";
import vertexShaderGround from "./shaders/grass/ground-vertex.glsl";
import fragmnetShaderGround from "./shaders/grass/ground-fragment.glsl";
import vertexShaderSky from "./shaders/grass/sky-vertex.glsl";
import fragmnetShaderSky from "./shaders/grass/sky-fragment.glsl";
import vertexShaderGrass from "./shaders/grass/grass-vertex.glsl";
import fragmnetShaderGrass from "./shaders/grass/grass-fragment.glsl";

const NUM_GRASS = 1024 * 80;
const GRASS_SEGMENTS = 8;
const GRASS_VERTICES = (GRASS_SEGMENTS + 1) * 2;
const GRASS_PATCH_SIZE = 20;
const GRASS_WIDTH = 0.25;
const GRASS_HEIGHT = 2;

const diffuseTexture = textureLoader.load("/textures/grid.png");
diffuseTexture.wrapS = THREE.RepeatWrapping;
diffuseTexture.wrapT = THREE.RepeatWrapping;

const tileDataTexture = textureLoader.load("/textures/tileData.jpg");

const light = new THREE.DirectionalLight(0xffffff, 1.0);
light.position.set(1, 1, 1);
light.lookAt(0, 0, 0);

const groundMaterial = new THREE.ShaderMaterial({
  uniforms: {
    uDiffuseTexture: new THREE.Uniform(diffuseTexture),
  },
  vertexShader: vertexShaderGround,
  fragmentShader: fragmnetShaderGround,
});

const planeGeometry = new THREE.PlaneGeometry(1, 1, 512, 512);
const plane = new THREE.Mesh(planeGeometry, groundMaterial);
plane.rotateX(-Math.PI / 2);
plane.scale.setScalar(40);

const skyGeometry = new THREE.SphereGeometry(50, 32, 15);
const skyMaterial = new THREE.ShaderMaterial({
  uniforms: {
    uResolution: new THREE.Uniform(
      new THREE.Vector2(
        sizes.width * renderer.getPixelRatio(),
        sizes.height * renderer.getPixelRatio(),
      ),
    ),
  },
  vertexShader: vertexShaderSky,
  fragmentShader: fragmnetShaderSky,
  side: THREE.BackSide,
});
const sky = new THREE.Mesh(skyGeometry, skyMaterial);

const createGeometry = () => {
  const indices = [];

  for (let i = 0; i < GRASS_SEGMENTS; ++i) {
    const vi = i * 2;
    indices[i * 12 + 0] = vi + 0;
    indices[i * 12 + 1] = vi + 1;
    indices[i * 12 + 2] = vi + 2;

    indices[i * 12 + 3] = vi + 2;
    indices[i * 12 + 4] = vi + 1;
    indices[i * 12 + 5] = vi + 3;

    const fi = GRASS_VERTICES + vi;
    indices[i * 12 + 6] = fi + 2;
    indices[i * 12 + 7] = fi + 1;
    indices[i * 12 + 8] = fi + 0;

    indices[i * 12 + 9] = fi + 3;
    indices[i * 12 + 10] = fi + 1;
    indices[i * 12 + 11] = fi + 2;
  }

  const geometry = new THREE.InstancedBufferGeometry();
  geometry.instanceCount = NUM_GRASS;
  geometry.setIndex(indices);
  geometry.boundingSphere = new THREE.Sphere(
    new THREE.Vector3(0, 0, 0),
    1 + GRASS_PATCH_SIZE * 2,
  );

  return geometry;
};

const grassMaterial = new THREE.ShaderMaterial({
  uniforms: {
    uGrassParams: new THREE.Uniform(
      new THREE.Vector4(
        GRASS_SEGMENTS,
        GRASS_PATCH_SIZE,
        GRASS_WIDTH,
        GRASS_HEIGHT,
      ),
    ),
    uTime: new THREE.Uniform(0),
    uResolution: new THREE.Uniform(
      new THREE.Vector2(
        sizes.width * renderer.getPixelRatio(),
        sizes.height * renderer.getPixelRatio(),
      ),
    ),
    uTileDataTexture: new THREE.Uniform(tileDataTexture),
    uGrassAtlas: new THREE.Uniform(null),
  },
  vertexShader: vertexShaderGrass,
  fragmentShader: fragmnetShaderGrass,
});
const grassGeometry = createGeometry();
const grass = new THREE.Mesh(grassGeometry, grassMaterial);

const atlas = new TextureAtlas();
atlas.Load("diffuse", ["/textures/grass1.png", "/textures/grass2.png"]);
atlas.onLoad = () => {
  grassMaterial.uniforms.uGrassAtlas.value = atlas.Info["diffuse"].atlas;
};

resizeSubscribers.push((s) => {
  const width = s.width * renderer.getPixelRatio();
  const height = s.height * renderer.getPixelRatio();
  skyMaterial.uniforms.uResolution.value.set(width, height);
  grassMaterial.uniforms.uResolution.value.set(width, height);
});

tickSubscribers.push((elapsedTime) => {
  grassMaterial.uniforms.uTime.value = elapsedTime;
});

export const initGrass = () => {
  setCamera("perspective");
  perspectiveCamera.position.set(10, 5, 5);
  perspectiveCamera.fov = 60;
  scene.add(light);
  scene.add(plane);
  scene.add(sky);
  scene.add(grass);
  console.log("grass");
};
