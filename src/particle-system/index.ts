import * as THREE from "three";
import {
  renderer,
  resizeSubscribers,
  scene,
  tickSubscribers,
  setCamera,
  perspectiveCamera,
  rgbeLoader,
} from "../setup";
import { ParticleProject } from "./particles";

export const initParticles = () => {
  setCamera("perspective");
  perspectiveCamera.position.set(20, 1, 20);

  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.setClearColor(0x000000);

  scene.backgroundBlurriness = 0.0;
  scene.backgroundIntensity = 0.2;
  scene.environmentIntensity = 1.0;

  rgbeLoader.load("./envs/moonless_golf_2k.hdr", (hdrTexture) => {
    hdrTexture.mapping = THREE.EquirectangularReflectionMapping;
    scene.background = hdrTexture;
    scene.environment = hdrTexture;
  });

  const particleProject = new ParticleProject();

  resizeSubscribers.push(() => {});

  tickSubscribers.push((elapsedTime, deltaTime) => {
    particleProject.step(elapsedTime, deltaTime);
  });

  console.log("particles");
};
