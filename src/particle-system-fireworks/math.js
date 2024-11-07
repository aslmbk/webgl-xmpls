import * as THREE from "three";

import MersenneTwister from "mersenne-twister";

const MT_ = new MersenneTwister(1);

function random() {
  return MT_.random();
}

class Interpolant {
  #frames_ = null;
  #interpolator_ = null;
  #resultBuffer_ = null;

  constructor(frames, stride) {
    const times = [];
    const values = [];

    for (let i = 0; i < frames.length; ++i) {
      times.push(frames[i].time);
      values.push(...frames[i].value);
    }

    this.#resultBuffer_ = new Float32Array(stride);

    this.#frames_ = frames;
    this.#interpolator_ = new THREE.LinearInterpolant(times, values, stride, this.#resultBuffer_);
  }

  get Frames() {
    return this.#frames_;
  }

  evaluate(time) {
    this.#interpolator_.evaluate(time);
    return this.onEvaluate(this.#resultBuffer_);
  }

  onEvaluate(result) {
    return result;
  }
}

class Vec3Interpolant extends Interpolant {
  constructor(frames) {
    super(frames, 3);
  }

  onEvaluate(result) {
    return new THREE.Vector3(result[0], result[1], result[2]);
  }
}

class ColorInterpolant extends Interpolant {
  constructor(frames) {
    for (let i = 0; i < frames.length; ++i) {
      frames[i].value = [frames[i].value.r, frames[i].value.g, frames[i].value.b];
    }
    super(frames, 3);
  }

  onEvaluate(result) {
    return new THREE.Color(result[0], result[1], result[2]);
  }

  toTexture(alphaInterpolant) {
    const frames = this.Frames;
    const alphaFrames = alphaInterpolant.Frames;

    const maxFrameTime = Math.max(frames[frames.length - 1].time, alphaFrames[alphaFrames.length - 1].time);

    let smallestStep = 0.5;
    for (let i = 1; i < frames.length; ++i) {
      const stepSize = (frames[i].time - frames[i - 1].time) / maxFrameTime;
      smallestStep = Math.min(smallestStep, stepSize);
    }
    for (let i = 1; i < alphaFrames.length; ++i) {
      const stepSize = (alphaFrames[i].time - alphaFrames[i - 1].time) / maxFrameTime;
      smallestStep = Math.min(smallestStep, stepSize);
    }

    // Compute recommended size
    const recommendedSize = Math.ceil(1 / smallestStep);

    // Make 1D texture with the values
    const width = recommendedSize + 1;
    const data = new Float32Array(width * 4);

    for (let i = 0; i < width; ++i) {
      const t = i / (width - 1);
      const color = this.evaluate(t * maxFrameTime);
      const alpha = alphaInterpolant.evaluate(t * maxFrameTime);

      data[i * 4 + 0] = color.r;
      data[i * 4 + 1] = color.g;
      data[i * 4 + 2] = color.b;
      data[i * 4 + 3] = alpha;
    }

    const dt = new THREE.DataTexture(data, width, 1, THREE.RGBAFormat, THREE.FloatType);
    dt.minFilter = THREE.LinearFilter;
    dt.magFilter = THREE.LinearFilter;
    dt.wrapS = THREE.ClampToEdgeWrapping;
    dt.wrapT = THREE.ClampToEdgeWrapping;
    dt.needsUpdate = true;
    return dt;
  }
}

class FloatInterpolant extends Interpolant {
  constructor(frames) {
    for (let i = 0; i < frames.length; ++i) {
      frames[i].value = [frames[i].value];
    }
    super(frames, 1);
  }

  onEvaluate(result) {
    return result[0];
  }

  toTexture() {
    const frames = this.Frames;
    const maxFrameTime = frames[frames.length - 1].time;

    let smallestStep = 0.5;
    for (let i = 1; i < frames.length; ++i) {
      const stepSize = (frames[i].time - frames[i - 1].time) / maxFrameTime;
      smallestStep = Math.min(smallestStep, stepSize);
    }

    // Compute recommended size
    const recommendedSize = Math.ceil(1 / smallestStep);

    // Make 1D texture with the values
    const width = recommendedSize + 1;
    const data = new Float32Array(width);

    for (let i = 0; i < width; ++i) {
      const t = i / (width - 1);
      const value = this.evaluate(t * maxFrameTime);
      data[i] = value;
    }

    const dt = new THREE.DataTexture(data, width, 1, THREE.RedFormat, THREE.FloatType);
    dt.minFilter = THREE.LinearFilter;
    dt.magFilter = THREE.LinearFilter;
    dt.wrapS = THREE.ClampToEdgeWrapping;
    dt.wrapT = THREE.ClampToEdgeWrapping;
    dt.needsUpdate = true;
    return dt;
  }
}

export { random, Vec3Interpolant, FloatInterpolant, ColorInterpolant };
