import * as THREE from "three";
import {
  renderer,
  resizeSubscribers,
  scene,
  sizes,
  textureLoader,
  tickSubscribers,
  setCamera,
} from "./setup";
import vertexShader from "./shaders/vertex.glsl";
import fragmentShader from "./shaders/fragment.glsl";

export const initOrthographic = () => {
  setCamera("orthographic");
  const dogTexture = textureLoader.load("/textures/dog.jpg");

  const plane = new THREE.Mesh(
    new THREE.PlaneGeometry(),
    new THREE.ShaderMaterial({
      uniforms: {
        uTime: new THREE.Uniform(0),
        uResolution: new THREE.Uniform(
          new THREE.Vector2(
            sizes.width * renderer.getPixelRatio(),
            sizes.height * renderer.getPixelRatio(),
          ),
        ),
        uTexture: new THREE.Uniform(dogTexture),
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
    }),
  );
  plane.scale.setScalar(1.0);
  plane.position.set(0.5, 0.5, 0);
  scene.add(plane);

  resizeSubscribers.push((s) => {
    plane.material.uniforms.uResolution.value.set(
      s.width * renderer.getPixelRatio(),
      s.height * renderer.getPixelRatio(),
    );
  });

  tickSubscribers.push((elapsedTime) => {
    plane.material.uniforms.uTime.value = elapsedTime;
  });
  console.log("orthographic");
};
