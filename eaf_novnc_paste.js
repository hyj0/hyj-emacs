
const CANVAS_SELECTOR = "canvas";
const MIDDLE_MOUSE_BUTTON = 1;

let canvas;


function waitForCanvas() {
  canvas = document.querySelector(CANVAS_SELECTOR);

  if (canvas) {
    initCanvas();
  } else {
    console.log("NoVNC canvas not found. Retrying...");
  }
}

function initCanvas() {
  console.log("NoVNC detected. Middle-click paste enabled.");
  canvas.id = "canvas-id";
}


function sendString(text) {
    if (!canvas) {
	initCanvas();
    }
    if (!canvas) {
	console.log("no in NoVNC!!!");
	return;
    }
    if (canvas != document.activeElement) {
	console.log("no in NoVNC canvas!!!");
	return;
    }
    text.split("").forEach((char, index) => {
    setTimeout(() => {
      const needsShift = /[A-Z!@#$%^&*()_+{}:"<>?~|]/.test(char);
      const event = new KeyboardEvent("keydown", { key: char, shiftKey: needsShift });

      if (needsShift) {
        const shiftDownEvent = new KeyboardEvent("keydown", { keyCode: 16 });
        canvas.dispatchEvent(shiftDownEvent);
      }

      canvas.dispatchEvent(event);

      if (needsShift) {
        const shiftUpEvent = new KeyboardEvent("keyup", { keyCode: 16 });
        canvas.dispatchEvent(shiftUpEvent);
      }

      const keyUpEvent = new KeyboardEvent("keyup", { key: char });
      canvas.dispatchEvent(keyUpEvent);
	console.log(needsShift + " " + char + " "  + index);
    }, index * 10);
  });
}

waitForCanvas();
