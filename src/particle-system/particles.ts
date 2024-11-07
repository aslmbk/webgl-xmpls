import * as PARTICLES from "./particle-system";
import * as THREE from "three";
import vertexShader from "../shaders/particles/vertex.glsl";
import fragmentShader from "../shaders/particles/fragment.glsl";
import { scene, textureLoader } from "../setup";
import { ColorInterpolant, FloatInterpolant } from "./math";

export class ParticleProject {
  particleSystem: PARTICLES.ParticleSystem;
  material: THREE.ShaderMaterial;

  constructor() {
    const sizeOverLife = new FloatInterpolant([
      { time: 0, value: 2 },
      { time: 0.1, value: 5 },
      { time: 5, value: 0 },
    ]);

    const alphaOverLife = new FloatInterpolant([
      { time: 0, value: 0 },
      { time: 0.25, value: 1 },
      { time: 4.5, value: 1 },
      { time: 5, value: 0 },
    ]);

    const colorOverLife = new ColorInterpolant([
      { time: 0, value: new THREE.Color().setHSL(0, 1, 0.75) },
      { time: 2, value: new THREE.Color().setHSL(0.5, 1, 0.5) },
      { time: 5, value: new THREE.Color().setHSL(1, 1, 0.5) },
    ]);

    const twinkleOverLife = new FloatInterpolant([
      { time: 0, value: 0 },
      { time: 3, value: 1 },
      { time: 4, value: 1 },
    ]);

    const starTexture = textureLoader.load("./textures/star.png");
    this.material = new THREE.ShaderMaterial({
      vertexShader,
      fragmentShader,
      uniforms: {
        time: new THREE.Uniform(0),
        map: new THREE.Uniform(starTexture),
        sizeOverLife: new THREE.Uniform(sizeOverLife.toTexture()),
        colorOverLife: new THREE.Uniform(colorOverLife.toTexture(alphaOverLife)),
        twinkleOverLife: new THREE.Uniform(twinkleOverLife.toTexture()),
        spinSpeed: new THREE.Uniform(0),
      },
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });

    this.particleSystem = new PARTICLES.ParticleSystem();

    const maxParticles = 500;

    const particleRenderer = new PARTICLES.ParticleRenderer({ scene, maxParticles, material: this.material });
    const shape = new PARTICLES.PointShape();

    const emitterParams = new PARTICLES.EmitterParams({ particleRenderer, shape });
    emitterParams.emissionRate = 10;
    emitterParams.maxParticles = maxParticles;
    emitterParams.maxEmission = Infinity;
    emitterParams.maxLife = 3;

    const emitter = new PARTICLES.Emitter(emitterParams);
    this.particleSystem.addEmitter(emitter);
  }

  step(elapsedTime: number, deltaTime: number) {
    this.particleSystem.step(elapsedTime, deltaTime);
  }
}
