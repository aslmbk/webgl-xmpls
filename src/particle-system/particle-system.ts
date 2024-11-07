import * as THREE from "three";
import { gravity } from "./math";

class Particle {
  position: THREE.Vector3;
  velocity: THREE.Vector3;
  life = 0;
  maxLife = 5;

  constructor() {
    this.position = new THREE.Vector3();
    this.velocity = new THREE.Vector3();
  }
}

class ParticleSystem {
  emitters: Emitter[] = [];

  constructor() {}

  addEmitter(emitter: Emitter) {
    this.emitters.push(emitter);
  }

  step(elapsedTime: number, deltaTime: number) {
    this.emitters.forEach((emitter) => {
      emitter.step(elapsedTime, deltaTime);
    });
  }
}

class ParticleRenderer {
  geometry: THREE.BufferGeometry;
  scene: THREE.Object3D | THREE.Group | THREE.Scene | THREE.Mesh;
  maxParticles: number;
  material: THREE.ShaderMaterial;

  constructor({
    geometry = new THREE.BufferGeometry(),
    scene = new THREE.Group(),
    maxParticles = 100,
    material,
  }: {
    geometry?: THREE.BufferGeometry;
    scene?: THREE.Object3D | THREE.Group | THREE.Scene | THREE.Mesh;
    maxParticles?: number;
    material: THREE.ShaderMaterial;
  }) {
    this.geometry = geometry;
    this.scene = scene;
    this.maxParticles = maxParticles;
    this.material = material;

    const positions = new Float32Array(this.maxParticles * 3);
    const lives = new Float32Array(this.maxParticles);

    this.geometry.setAttribute("position", new THREE.Float32BufferAttribute(positions, 3));
    this.geometry.setAttribute("life", new THREE.Float32BufferAttribute(lives, 1));

    (this.geometry.attributes.position as THREE.BufferAttribute).setUsage(THREE.DynamicDrawUsage);
    (this.geometry.attributes.life as THREE.BufferAttribute).setUsage(THREE.DynamicDrawUsage);

    const particles = new THREE.Points(this.geometry, this.material);
    this.scene.add(particles);
  }

  updateFromParticles(particles: Particle[], elapsedTime: number) {
    for (let i = 0; i < particles.length; i++) {
      const p = particles[i];
      this.geometry.attributes.position.array[i * 3] = p.position.x;
      this.geometry.attributes.position.array[i * 3 + 1] = p.position.y;
      this.geometry.attributes.position.array[i * 3 + 2] = p.position.z;
      this.geometry.attributes.life.array[i] = p.life / p.maxLife;
    }

    this.geometry.attributes.position.needsUpdate = true;
    this.geometry.attributes.life.needsUpdate = true;

    this.geometry.setDrawRange(0, particles.length);
    this.material.uniforms.time.value = elapsedTime;
  }
}

class EmitterParams {
  maxLife = 5;
  maxParticles = 100;
  emissionRate = 1;
  maxEmission = 100;
  particleRenderer: ParticleRenderer;
  shape: EmitterShape;

  constructor({ particleRenderer, shape }: { particleRenderer: ParticleRenderer; shape: EmitterShape }) {
    this.particleRenderer = particleRenderer;
    this.shape = shape;
  }
}

class Emitter {
  particles: Particle[] = [];
  emissionTime = 0;
  numParticlesEmitted = 0;
  params: EmitterParams;

  constructor(params: EmitterParams) {
    this.params = params;
  }

  emitParticle() {
    const particle = this.params.shape.emit();
    particle.maxLife = this.params.maxLife;
    return particle;
  }

  canCreateParticle() {
    const secondsPerParticle = 1 / this.params.emissionRate;
    return (
      this.emissionTime >= secondsPerParticle &&
      this.numParticlesEmitted < this.params.maxEmission &&
      this.particles.length < this.params.maxParticles
    );
  }

  updateEmission(dt: number) {
    this.emissionTime += dt;
    const secondsPerParticle = 1 / this.params.emissionRate;

    while (this.canCreateParticle()) {
      this.emissionTime -= secondsPerParticle;
      this.numParticlesEmitted++;
      const particle = this.emitParticle();
      this.particles.push(particle);
    }
  }

  updateParticle(particle: Particle, dt: number) {
    particle.life = Math.min(particle.life + dt, particle.maxLife);

    const forces = gravity.clone().add(particle.velocity.clone().multiplyScalar(-0.1));
    particle.velocity.add(forces.multiplyScalar(dt));
    const displacement = particle.velocity.clone().multiplyScalar(dt);
    particle.position.add(displacement);
  }

  updateParticles(dt: number) {
    this.particles.forEach((particle) => {
      this.updateParticle(particle, dt);
    });
    this.particles = this.particles.filter((particle) => particle.life < particle.maxLife);
  }

  step(elapsedTime: number, deltaTime: number) {
    this.updateEmission(deltaTime);
    this.updateParticles(deltaTime);

    this.params.particleRenderer.updateFromParticles(this.particles, elapsedTime);
  }
}

class EmitterShape {
  constructor() {}

  emit() {
    return new Particle();
  }
}

class PointShape extends EmitterShape {
  position: THREE.Vector3;

  constructor() {
    super();
    this.position = new THREE.Vector3();
  }

  emit() {
    const particle = super.emit();
    particle.position.copy(this.position);
    return particle;
  }
}

export { Particle, ParticleSystem, Emitter, EmitterParams, EmitterShape, ParticleRenderer, PointShape };
