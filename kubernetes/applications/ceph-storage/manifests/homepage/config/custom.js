(() => {
    const CONFIG = {
        variant: "square",
        pixelSize: 2,
        color: "#B19EEF",
        patternScale: 1.5,
        patternDensity: 1.5,
        enableRipples: false,
        rippleSpeed: 0.7,
        rippleThickness: 0.27,
        rippleIntensityScale: 2.8,
        speed: 0.4,
        transparent: true,
        opacity: 0.5,
        edgeFade: 0.5,
        backgroundColor: "#0a0019",
    };

    const CANVAS_ID = "homepage-waves-bg";
    const MANAGED_ATTR = "data-pixel-bg-managed";

    const state = {
        canvas: null,
        ctx: null,
        host: null,
        offCanvas: null,
        offCtx: null,
        dotCanvas: null,
        dotCtx: null,
        maskCanvas: null,
        maskCtx: null,
        imgData: null,
        cols: 0,
        rows: 0,
        width: 0,
        height: 0,
        rafId: null,
        observer: null,
        mouse: {
            x: 0,
            y: 0,
            active: false,
        },
    };

    const bayer8x8 = [
        [0, 32, 8, 40, 2, 34, 10, 42],
        [48, 16, 56, 24, 50, 18, 58, 26],
        [12, 44, 4, 36, 14, 46, 6, 38],
        [60, 28, 52, 20, 62, 30, 54, 22],
        [3, 35, 11, 43, 1, 33, 9, 41],
        [51, 19, 59, 27, 49, 17, 57, 25],
        [15, 47, 7, 39, 13, 45, 5, 37],
        [63, 31, 55, 23, 61, 29, 53, 21],
    ];

    const bayerThresholds = bayer8x8.map((row) => row.map((value) => (value / 64) * 255));

    function hexToRgb(hex) {
        return {
            r: Number.parseInt(hex.slice(1, 3), 16),
            g: Number.parseInt(hex.slice(3, 5), 16),
            b: Number.parseInt(hex.slice(5, 7), 16),
        };
    }

    const baseColor = hexToRgb(CONFIG.color);

    function getHostElement() {
        return document.getElementById("background") || document.body;
    }

    function liftPageLayers() {
        Array.from(document.body.children).forEach((child) => {
            if (child.id === CANVAS_ID) return;

            if (child.getAttribute(MANAGED_ATTR) !== "true") {
                child.setAttribute(MANAGED_ATTR, "true");

                const computed = window.getComputedStyle(child);
                if (computed.position === "static") {
                    child.style.position = "relative";
                }

                if (!child.style.zIndex) {
                    child.style.zIndex = "1";
                }
            }
        });
    }

    function styleHost(host) {
        if (host.id === "background") {
            host.style.backgroundImage = "none";
            host.style.background = CONFIG.backgroundColor;
            host.style.opacity = "1";
        } else {
            host.style.position = host.style.position || "relative";
            host.style.background = CONFIG.backgroundColor;
        }

        host.style.overflow = "hidden";
    }

    function ensureCanvas() {
        const host = getHostElement();
        styleHost(host);

        const existing = document.getElementById(CANVAS_ID);
        if (existing && existing.parentElement !== host) {
            existing.remove();
        }

        let canvas = host.querySelector(`#${CANVAS_ID}`);
        if (!canvas) {
            canvas = document.createElement("canvas");
            canvas.id = CANVAS_ID;
            Object.assign(canvas.style, {
                position: host.id === "background" ? "absolute" : "fixed",
                inset: "0",
                width: host.id === "background" ? "100%" : "100vw",
                height: host.id === "background" ? "100%" : "100vh",
                display: "block",
                pointerEvents: "none",
                zIndex: "0",
                imageRendering: "pixelated",
                opacity: "1",
            });

            host.prepend(canvas);
        }

        state.host = host;
        state.canvas = canvas;
        state.ctx = canvas.getContext("2d", { alpha: CONFIG.transparent });

        liftPageLayers();
    }

    function ensureBuffers() {
        if (!state.offCanvas) {
            state.offCanvas = document.createElement("canvas");
            state.offCtx = state.offCanvas.getContext("2d", { willReadFrequently: true });
        }

        if (!state.dotCanvas) {
            state.dotCanvas = document.createElement("canvas");
            state.dotCtx = state.dotCanvas.getContext("2d");
        }

        if (CONFIG.variant === "circle" && !state.maskCanvas) {
            state.maskCanvas = document.createElement("canvas");
            state.maskCtx = state.maskCanvas.getContext("2d");
        }
    }

    function rebuildMask() {
        if (CONFIG.variant !== "circle" || !state.maskCanvas || !state.maskCtx) return;

        state.maskCanvas.width = state.width;
        state.maskCanvas.height = state.height;

        const pixelCanvas = document.createElement("canvas");
        pixelCanvas.width = CONFIG.pixelSize;
        pixelCanvas.height = CONFIG.pixelSize;

        const pixelCtx = pixelCanvas.getContext("2d");
        pixelCtx.fillStyle = "#ffffff";
        pixelCtx.beginPath();
        pixelCtx.arc(
            CONFIG.pixelSize / 2,
            CONFIG.pixelSize / 2,
            CONFIG.pixelSize / 2,
            0,
            Math.PI * 2,
        );
        pixelCtx.fill();

        const pattern = state.maskCtx.createPattern(pixelCanvas, "repeat");
        state.maskCtx.clearRect(0, 0, state.width, state.height);
        state.maskCtx.fillStyle = pattern;
        state.maskCtx.fillRect(0, 0, state.width, state.height);
    }

    function resize() {
        if (!state.canvas || !state.ctx) return;

        state.width = Math.max(window.innerWidth || 1, 1);
        state.height = Math.max(window.innerHeight || 1, 1);

        state.canvas.width = state.width;
        state.canvas.height = state.height;

        state.cols = Math.max(1, Math.ceil(state.width / CONFIG.pixelSize));
        state.rows = Math.max(1, Math.ceil(state.height / CONFIG.pixelSize));

        ensureBuffers();

        state.offCanvas.width = state.cols;
        state.offCanvas.height = state.rows;
        state.imgData = state.offCtx.createImageData(state.cols, state.rows);

        state.dotCanvas.width = state.width;
        state.dotCanvas.height = state.height;

        rebuildMask();
    }

    function rippleInfluence(x, y, time) {
        if (!CONFIG.enableRipples || !state.mouse.active) return 0;

        const dx = x - state.mouse.x;
        const dy = y - state.mouse.y;
        const distance = Math.hypot(dx, dy);
        const wave = Math.sin(distance * CONFIG.rippleThickness - time * CONFIG.rippleSpeed * 30);
        return (wave / (1 + distance * 0.02)) * CONFIG.rippleIntensityScale;
    }

    function drawFrame(timestamp) {
        if (!state.ctx || !state.imgData) {
            state.rafId = window.requestAnimationFrame(drawFrame);
            return;
        }

        const time = timestamp * 0.0005 * CONFIG.speed;
        const data = state.imgData.data;
        const cx = state.cols / 2;
        const cy = state.rows / 2;
        const aspect = state.cols / state.rows;

        for (let y = 0; y < state.rows; y += 1) {
            for (let x = 0; x < state.cols; x += 1) {
                const index = (y * state.cols + x) * 4;

                const nx = (x / state.cols) * aspect * CONFIG.patternScale * 10;
                const ny = (y / state.rows) * CONFIG.patternScale * 10;

                let value =
                    Math.sin(nx + time * 0.5) +
                    Math.cos(ny - time * 0.4) +
                    Math.sin(nx * 0.6 - ny * 0.6 + time * 0.7) +
                    Math.cos(nx * 0.4 + ny * 0.4 - time * 0.6);

                let fluid = (value + 1.2) / 3.5;
                fluid = Math.pow(Math.max(0, fluid), 1.6);
                fluid *= CONFIG.patternDensity;
                fluid += rippleInfluence(x, y, time) * 0.03;

                if (CONFIG.edgeFade > 0) {
                    const distNorm = Math.sqrt(
                        Math.pow((x - cx) / cx, 2) + Math.pow((y - cy) / cy, 2),
                    );
                    let fade = Math.max(0, 1 - distNorm * 0.8);
                    fade = fade * fade * (3 - 2 * fade);
                    fade = Math.pow(fade, CONFIG.edgeFade);
                    fluid *= fade;
                }

                const intensity = fluid * 255;
                const threshold = bayerThresholds[y % 8][x % 8];

                if (intensity > threshold) {
                    data[index] = baseColor.r;
                    data[index + 1] = baseColor.g;
                    data[index + 2] = baseColor.b;
                    data[index + 3] = 255;
                } else {
                    data[index] = 0;
                    data[index + 1] = 0;
                    data[index + 2] = 0;
                    data[index + 3] = 0;
                }
            }
        }

        state.offCtx.putImageData(state.imgData, 0, 0);

        state.dotCtx.clearRect(0, 0, state.width, state.height);
        state.dotCtx.imageSmoothingEnabled = false;
        state.dotCtx.drawImage(
            state.offCanvas,
            0,
            0,
            state.cols,
            state.rows,
            0,
            0,
            state.width,
            state.height,
        );

        if (CONFIG.variant === "circle" && state.maskCanvas) {
            state.dotCtx.globalCompositeOperation = "destination-in";
            state.dotCtx.drawImage(state.maskCanvas, 0, 0);
            state.dotCtx.globalCompositeOperation = "source-over";
        }

        if (CONFIG.transparent) {
            state.ctx.clearRect(0, 0, state.width, state.height);
        } else {
            state.ctx.fillStyle = CONFIG.backgroundColor;
            state.ctx.fillRect(0, 0, state.width, state.height);
        }

        state.ctx.globalAlpha = CONFIG.opacity;
        state.ctx.drawImage(state.dotCanvas, 0, 0);
        state.ctx.globalAlpha = 1;

        state.rafId = window.requestAnimationFrame(drawFrame);
    }

    function bindEvents() {
        window.addEventListener("resize", resize, { passive: true });

        window.addEventListener("pointermove", (event) => {
            state.mouse.x = (event.clientX / Math.max(state.width, 1)) * state.cols;
            state.mouse.y = (event.clientY / Math.max(state.height, 1)) * state.rows;
            state.mouse.active = true;
        }, { passive: true });

        window.addEventListener("pointerleave", () => {
            state.mouse.active = false;
        }, { passive: true });

        document.addEventListener("visibilitychange", () => {
            if (document.hidden) {
                if (state.rafId) {
                    window.cancelAnimationFrame(state.rafId);
                    state.rafId = null;
                }
                return;
            }

            if (!state.rafId) {
                state.rafId = window.requestAnimationFrame(drawFrame);
            }
        });

        state.observer = new MutationObserver(() => {
            const nextHost = getHostElement();
            if (nextHost !== state.host) {
                ensureCanvas();
                resize();
            }
        });

        state.observer.observe(document.body, {
            childList: true,
        });
    }

    function init() {
        const existing = document.getElementById(CANVAS_ID);
        if (existing) {
            existing.remove();
        }

        ensureCanvas();
        resize();
        bindEvents();

        if (state.rafId) {
            window.cancelAnimationFrame(state.rafId);
        }

        state.rafId = window.requestAnimationFrame(drawFrame);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init, { once: true });
    } else {
        init();
    }
})();
