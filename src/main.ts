import { initGrass } from "./grass";
import { initOrthographic } from "./orthographic";
import { initPerspective } from "./perspective";
import { initParticles } from "./particle-system";

type AppType = "orthographic" | "perspective" | "grass" | "particle-system";

const initApp = (type: AppType) => {
  if (type === "orthographic") {
    initOrthographic();
  } else if (type === "perspective") {
    initPerspective();
  } else if (type === "grass") {
    initGrass();
  } else if (type === "particle-system") {
    initParticles();
  }
};

initApp("particle-system");
