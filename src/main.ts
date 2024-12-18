import { initGrass } from "./grass";
import { initOrthographic } from "./orthographic";
import { initPerspective } from "./perspective";
import { initParticles } from "./particle-system";
import { initFireworks } from "./particle-system-fireworks/main.js";
import { initFire } from "./particle-system-fire/main.js";

type AppType = "orthographic" | "perspective" | "grass" | "particle-system" | "fireworks" | "fire";

const initApp = (type: AppType) => {
  if (type === "orthographic") {
    initOrthographic();
  } else if (type === "perspective") {
    initPerspective();
  } else if (type === "grass") {
    initGrass();
  } else if (type === "particle-system") {
    initParticles();
  } else if (type === "fireworks") {
    initFireworks();
  } else if (type === "fire") {
    initFire();
  }
};

initApp("fire");
