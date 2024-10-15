import { initGrass } from "./grass";
import { initOrthographic } from "./orthographic";
import { initPerspective } from "./perspective";

type AppType = "orthographic" | "perspective" | "grass";

const initApp = (type: AppType) => {
  if (type === "orthographic") {
    initOrthographic();
  } else if (type === "perspective") {
    initPerspective();
  } else if (type === "grass") {
    initGrass();
  }
};

initApp("grass");
