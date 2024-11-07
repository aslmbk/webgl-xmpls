import * as THREE from "three";
import * as MATH from "./math.js";
import * as PARTICLES from "./particle-system.js";
import * as NOISE from "./noise.js";
import {
  renderer,
  scene,
  setCamera,
  perspectiveCamera,
  rgbeLoader,
  textureLoader,
  tickSubscribers,
  gltfLoader,
} from "../setup";
import vertexShader from "../shaders/fire/vertex.glsl";
import fragmentShader from "../shaders/fire/fragment.glsl";

class ParticleProject {
  #particleSystem_ = null;
  #smokeMaterial_ = null;
  #campfireLight_ = null;

  constructor() {}

  async onSetupProject() {
    rgbeLoader.load("./envs/moonless_golf_2k.hdr", (hdrTexture) => {
      hdrTexture.mapping = THREE.EquirectangularReflectionMapping;
      scene.background = hdrTexture;
      scene.environment = hdrTexture;
    });

    const whiteSquareTexture = textureLoader.load("./textures/whitesquare.png");
    whiteSquareTexture.wrapS = THREE.RepeatWrapping;
    whiteSquareTexture.wrapT = THREE.RepeatWrapping;
    whiteSquareTexture.repeat.set(500, 500);
    whiteSquareTexture.anisotropy = 16;

    const groundGeo = new THREE.PlaneGeometry(500, 500);
    const groundMat = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      map: whiteSquareTexture,
      metalness: 0.5,
      roughness: 0.6,
    });
    const groundMesh = new THREE.Mesh(groundGeo, groundMat);
    groundMesh.rotation.x = -Math.PI / 2;
    groundMesh.receiveShadow = true;
    scene.add(groundMesh);

    gltfLoader.load("./models/tree1.glb", (gltf) => {
      gltf.scene.traverse((c) => {
        c.castShadow = true;
        c.receiveShadow = true;
      });
      gltf.scene.scale.setScalar(0.25);

      const positions = [new THREE.Vector3(-15, 0, 0), new THREE.Vector3(-20, 0, 10)];

      for (let i = 0; i < positions.length; i++) {
        const tree = gltf.scene.clone();
        tree.position.copy(positions[i]);
        scene.add(tree);
      }
    });

    gltfLoader.load("./models/tree2.glb", (gltf) => {
      gltf.scene.traverse((c) => {
        c.castShadow = true;
        c.receiveShadow = true;
      });
      gltf.scene.scale.setScalar(0.25);

      const positions = [new THREE.Vector3(-15, 0, 12), new THREE.Vector3(20, 0, 15)];

      for (let i = 0; i < positions.length; i++) {
        const tree = gltf.scene.clone();
        tree.position.copy(positions[i]);
        scene.add(tree);
      }
    });

    gltfLoader.load("./models/campfire-logs.glb", (gltf) => {
      gltf.scene.traverse((c) => {
        c.castShadow = true;
        c.receiveShadow = true;
      });

      scene.add(gltf.scene);
    });

    this.#campfireLight_ = new THREE.PointLight(0xf8b867, 100);
    this.#campfireLight_.position.set(0, 4, 0);
    this.#campfireLight_.castShadow = true;
    this.#campfireLight_.shadow.mapSize.set(1024, 1024);
    scene.add(this.#campfireLight_);

    const helper = new THREE.PointLightHelper(this.#campfireLight_);
    scene.add(helper);

    this.#createParticleSystem_();
  }

  #createParticleSystem_() {
    const fireTexture = textureLoader.load("./textures/fire.png");
    const smokeTexture = textureLoader.load("./textures/smoke.png");

    this.#particleSystem_ = new PARTICLES.ParticleSystem();

    // Fire
    {
      const sizeOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 3 },
        { time: 0.25, value: 10 },
        { time: 2, value: 0 },
      ]);

      const twinkleOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 1, value: 0 },
      ]);

      const alphaOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 0.25, value: 1 },
        { time: 2, value: 0 },
      ]);

      const colourOverLife = new MATH.ColorInterpolant([
        { time: 0, value: new THREE.Color(0xffffc0) },
        { time: 1, value: new THREE.Color(0xff0000) },
      ]);

      const fireMaterial = new THREE.ShaderMaterial({
        uniforms: {
          time: { value: 0 },
          map: { value: fireTexture },
          sizeOverLife: { value: sizeOverLife.toTexture() },
          colourOverLife: { value: colourOverLife.toTexture(alphaOverLife) },
          twinkleOverLife: { value: twinkleOverLife.toTexture() },
          spinSpeed: { value: 0 },
          lightFactor: { value: 0 },
        },
        vertexShader,
        fragmentShader,
        transparent: true,
        depthWrite: false,
        depthTest: true,
        // blending: THREE.AdditiveBlending,
        blending: THREE.CustomBlending,
        blendEquation: THREE.AddEquation,
        blendSrc: THREE.OneFactor,
        blendDst: THREE.OneMinusSrcAlphaFactor,
      });

      const fireAttractor = new PARTICLES.ParticleAttractor();
      fireAttractor.position.set(0, 6, 0);
      fireAttractor.intensity = 4;
      fireAttractor.radius = 3;

      const fireEmitterParams = new PARTICLES.EmitterParams();
      fireEmitterParams.shape = new PARTICLES.PointShape();
      fireEmitterParams.shape.positionRadiusVariance = 1;
      fireEmitterParams.maxLife = 2;
      fireEmitterParams.maxParticles = 200;
      fireEmitterParams.emissionRate = 50;
      fireEmitterParams.maxEmission = Number.MAX_SAFE_INTEGER;
      fireEmitterParams.velocityMagnitude = 4;
      fireEmitterParams.rotationAngularVariance = Math.PI / 6;
      fireEmitterParams.gravity = false;
      fireEmitterParams.spinSpeed = Math.PI / 2;
      fireEmitterParams.attractors.push(fireAttractor);

      const fireRendererParams = new PARTICLES.ParticleRendererParams();
      fireRendererParams.maxParticles = fireEmitterParams.maxParticles;

      fireEmitterParams.renderer = new PARTICLES.ParticleRenderer();
      fireEmitterParams.renderer.initialize(fireMaterial, fireRendererParams);

      const fireEmitter = new PARTICLES.Emitter(fireEmitterParams);

      this.#particleSystem_.addEmitter(fireEmitter);

      scene.add(fireRendererParams.group);
    }

    // Smoke
    {
      const sizeOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 8 },
        { time: 6, value: 24 },
      ]);

      const twinkleOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 1, value: 0 },
      ]);

      const alphaOverLife = new MATH.FloatInterpolant([
        { time: 0, value: 0 },
        { time: 0.5, value: 0.85 },
        { time: 6, value: 0 },
      ]);

      const colourOverLife = new MATH.ColorInterpolant([
        { time: 0, value: new THREE.Color(0xc0c0c0) },
        { time: 6, value: new THREE.Color(0x404040) },
      ]);

      const smokeMaterial = new THREE.ShaderMaterial({
        uniforms: {
          time: { value: 0 },
          map: { value: smokeTexture },
          sizeOverLife: { value: sizeOverLife.toTexture() },
          colourOverLife: { value: colourOverLife.toTexture(alphaOverLife) },
          twinkleOverLife: { value: twinkleOverLife.toTexture() },
          spinSpeed: { value: 0 },
          lightFactor: { value: 1.0 },
          lightIntensity: { value: 4.0 },
        },
        vertexShader,
        fragmentShader,
        transparent: true,
        depthWrite: false,
        depthTest: true,
        // blending: THREE.NormalBlending,
        blending: THREE.CustomBlending,
        blendEquation: THREE.AddEquation,
        blendSrc: THREE.OneFactor,
        blendDst: THREE.OneMinusSrcAlphaFactor,
      });

      this.#smokeMaterial_ = smokeMaterial;

      const smokeEmitterParams = new PARTICLES.EmitterParams();
      smokeEmitterParams.shape = new PARTICLES.PointShape();
      smokeEmitterParams.shape.position.set(0, 8, 0);
      smokeEmitterParams.shape.positionRadiusVariance = 1;
      smokeEmitterParams.maxLife = 6;
      smokeEmitterParams.maxParticles = 500;
      smokeEmitterParams.emissionRate = 40;
      smokeEmitterParams.maxEmission = Number.MAX_SAFE_INTEGER;
      smokeEmitterParams.velocityMagnitude = 4;
      smokeEmitterParams.rotationAngularVariance = Math.PI / 8;
      smokeEmitterParams.gravity = false;
      smokeEmitterParams.spinSpeed = Math.PI / 8;
      smokeEmitterParams.dragCoefficient = 0.25;

      const smokeRendererParams = new PARTICLES.ParticleRendererParams();
      smokeRendererParams.maxParticles = smokeEmitterParams.maxParticles;

      smokeEmitterParams.renderer = new PARTICLES.ParticleRenderer();
      smokeEmitterParams.renderer.initialize(smokeMaterial, smokeRendererParams);

      const fireEmitter = new PARTICLES.Emitter(smokeEmitterParams);

      this.#particleSystem_.addEmitter(fireEmitter);

      scene.add(smokeRendererParams.group);
    }
  }

  onStep(timeElapsed, totalTime) {
    if (this.#particleSystem_) {
      this.#particleSystem_.step(timeElapsed, totalTime);
    }

    if (this.#campfireLight_) {
      const noiseValue = NOISE.noise1D(totalTime * 2);
      const intensity = MATH.remap(-1, 1, 15, 50, noiseValue);
      this.#campfireLight_.intensity = intensity;

      if (this.#smokeMaterial_) {
        this.#smokeMaterial_.uniforms.lightIntensity.value = MATH.remap(-1, 1, 0.75, 2.0, noiseValue);
      }
    }
  }
}

export const initFire = () => {
  setCamera("perspective");
  perspectiveCamera.position.set(20, 1, 20);

  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.setClearColor(0x000000);

  scene.backgroundBlurriness = 0.0;
  scene.backgroundIntensity = 0.025;
  scene.environmentIntensity = 0.025;

  const app = new ParticleProject();
  app.onSetupProject();

  tickSubscribers.push((elapsedTime, deltaTime) => {
    app.onStep(deltaTime, elapsedTime);
  });

  console.log("fire");
};
