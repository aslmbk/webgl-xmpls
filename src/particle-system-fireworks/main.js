import * as THREE from "three";
import * as MATH from "./math.js";
import * as PARTICLES from "./particle-system.js";
import { renderer, scene, setCamera, perspectiveCamera, rgbeLoader, textureLoader, tickSubscribers } from "../setup";
import vertexShader from "../shaders/particles/vertex.glsl";
import fragmentShader from "../shaders/particles/fragment.glsl";

class ParticleProject {
  #particleSystem_ = null;
  #particleMaterial_ = null;
  #smokeMaterial_ = null;

  constructor() {}

  async onSetupProject() {
    rgbeLoader.load("./envs/moonless_golf_2k.hdr", (hdrTexture) => {
      hdrTexture.mapping = THREE.EquirectangularReflectionMapping;
      scene.background = hdrTexture;
      scene.environment = hdrTexture;
    });

    const starTexture = textureLoader.load("./textures/star.png");
    const smokeTexture = textureLoader.load("./textures/smoke.png");

    {
      const sizeOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 5 },
        { time: 5, value: 15 },
      ]);

      const alphaOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 1, value: 1 },
        { time: 5, value: 0 },
      ]);

      const colorOverLife = new MATH.ColorInterpolant([
        { time: 0, value: new THREE.Color().setHSL(0, 1, 0.5) },
        { time: 1, value: new THREE.Color().setHSL(0.25, 1, 0.5) },
        { time: 2, value: new THREE.Color().setHSL(0.5, 1, 0.5) },
        { time: 3, value: new THREE.Color().setHSL(0.75, 1, 0.5) },
        { time: 4, value: new THREE.Color().setHSL(1, 1, 0.5) },
      ]);

      const twinkleOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 1, value: 0 },
      ]);

      const material = new THREE.ShaderMaterial({
        uniforms: {
          time: { value: 0 },
          map: { value: smokeTexture },
          sizeOverLife: { value: sizeOverLife.toTexture() },
          colorOverLife: { value: colorOverLife.toTexture(alphaOverLife) },
          twinkleOverLife: { value: twinkleOverLife.toTexture() },
          spinSpeed: { value: 0 },
        },
        vertexShader,
        fragmentShader,
        depthWrite: false,
        depthTest: true,
        transparent: true,
        blending: THREE.AdditiveBlending,
      });

      this.#smokeMaterial_ = material;
    }

    {
      const sizeOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 2 },
        { time: 0.1, value: 5 },
        { time: 5, value: 0 },
      ]);

      const alphaOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 0.25, value: 1 },
        { time: 4.5, value: 1 },
        { time: 5, value: 0 },
      ]);

      const colorOverLife = new MATH.ColorInterpolant([
        { time: 0, value: new THREE.Color().setHSL(0, 1, 0.75) },
        { time: 2, value: new THREE.Color().setHSL(0.5, 1, 0.5) },
        { time: 5, value: new THREE.Color().setHSL(1, 1, 0.5) },
      ]);

      const twinkleOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 3, value: 1 },
        { time: 4, value: 1 },
      ]);

      const material = new THREE.ShaderMaterial({
        uniforms: {
          time: { value: 0 },
          map: { value: starTexture },
          sizeOverLife: { value: sizeOverLife.toTexture() },
          colorOverLife: { value: colorOverLife.toTexture(alphaOverLife) },
          twinkleOverLife: { value: twinkleOverLife.toTexture() },
          spinSpeed: { value: 0 },
        },
        vertexShader,
        fragmentShader,
        depthWrite: false,
        depthTest: true,
        transparent: true,
        blending: THREE.AdditiveBlending,
      });

      this.#particleMaterial_ = material;
    }

    this.#createParticleSystem_();
  }

  #createParticleSystem_() {
    this.#particleSystem_ = new PARTICLES.ParticleSystem();

    const emitterParams = new PARTICLES.EmitterParams();
    emitterParams.shape = new PARTICLES.PointShape();
    emitterParams.emissionRate = 1;
    emitterParams.maxParticles = 3;
    emitterParams.maxEmission = Number.MAX_SAFE_INTEGER;
    emitterParams.maxLife = 4;
    emitterParams.gravity = true;
    emitterParams.velocityMagnitude = 50;
    emitterParams.rotation = new THREE.Quaternion();
    emitterParams.rotationAngularVariance = Math.PI / 8;
    emitterParams.spinSpeed = Math.PI;

    emitterParams.onCreated = (particle) => {
      const smokeEmitterParams = new PARTICLES.EmitterParams();
      smokeEmitterParams.shape = new PARTICLES.PointShape();
      smokeEmitterParams.shape.positionRadiusVariance = 2;
      smokeEmitterParams.emissionRate = 50;
      smokeEmitterParams.maxParticles = 500;
      smokeEmitterParams.maxEmission = Number.MAX_SAFE_INTEGER;
      smokeEmitterParams.maxLife = 5;
      smokeEmitterParams.spinSpeed = Math.PI / 8;
      smokeEmitterParams.velocityMagnitude = 5;
      smokeEmitterParams.rotationAngularVariance = Math.PI / 8;

      const rendererParams = new PARTICLES.ParticleRendererParams();
      rendererParams.maxParticles = smokeEmitterParams.maxParticles;

      smokeEmitterParams.renderer = new PARTICLES.ParticleRenderer();
      smokeEmitterParams.renderer.initialize(this.#smokeMaterial_.clone(), rendererParams);

      const smokeEmitter = new PARTICLES.Emitter(smokeEmitterParams);

      this.#particleSystem_.addEmitter(smokeEmitter);

      scene.add(rendererParams.group);

      particle.attachedEmitter = smokeEmitter;
      particle.attachedShape = smokeEmitterParams.shape;
    };

    emitterParams.onStep = (particle) => {
      particle.attachedShape.position.copy(particle.position);
    };

    emitterParams.onDestroy = (particle) => {
      particle.attachedEmitter.stop();
      this.#createPopParticleSystem_(particle.position);
    };

    const rendererParams = new PARTICLES.ParticleRendererParams();
    rendererParams.maxParticles = emitterParams.maxParticles;

    const emitter = new PARTICLES.Emitter(emitterParams);

    this.#particleSystem_.addEmitter(emitter);

    scene.add(rendererParams.group);
  }

  #createPopParticleSystem_(pos) {
    const emitterParams = new PARTICLES.EmitterParams();
    emitterParams.shape = new PARTICLES.PointShape();
    emitterParams.shape.position.copy(pos);
    emitterParams.emissionRate = 5000;
    emitterParams.maxParticles = 500;
    emitterParams.maxEmission = 500;
    emitterParams.maxLife = 3;
    emitterParams.gravity = true;
    emitterParams.dragCoefficient = 4;
    emitterParams.velocityMagnitude = 75;
    emitterParams.velocityMagnitudeVariance = 10;
    emitterParams.rotationAngularVariance = 2 * Math.PI;
    emitterParams.spinSpeed = Math.PI;

    const rendererParams = new PARTICLES.ParticleRendererParams();
    rendererParams.maxParticles = emitterParams.maxParticles;

    emitterParams.renderer = new PARTICLES.ParticleRenderer();
    emitterParams.renderer.initialize(this.#particleMaterial_.clone(), rendererParams);

    const emitter = new PARTICLES.Emitter(emitterParams);

    this.#particleSystem_.addEmitter(emitter);

    scene.add(rendererParams.group);
  }

  onStep(timeElapsed, totalTime) {
    if (!this.#particleSystem_) {
      return;
    }

    this.#particleSystem_.step(timeElapsed, totalTime);

    if (!this.#particleSystem_.StillActive) {
      this.#particleSystem_.dispose();
      this.#particleSystem_ = null;
    }
  }
}

export const initFireworks = () => {
  setCamera("perspective");
  perspectiveCamera.position.set(80, 20, 80);

  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.setClearColor(0x000000);

  scene.backgroundBlurriness = 0.0;
  scene.backgroundIntensity = 0.01;
  scene.environmentIntensity = 1.0;

  const app = new ParticleProject();
  app.onSetupProject();

  tickSubscribers.push((elapsedTime, deltaTime) => {
    app.onStep(deltaTime, elapsedTime);
  });

  console.log("fireworks");
};
