import {vec3, vec4} from 'gl-matrix';
import Stats from 'stats-js';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import lambertVertSource from './shaders/lambert-vert.glsl?raw';
import lambertFragSource from './shaders/lambert-frag.glsl?raw';

import customVertSource from './shaders/custom-vert.glsl?raw';
import customFragSource from './shaders/custom-frag.glsl?raw';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
    tesselations: 8,
    'Load Scene': loadScene, // A function pointer, essentially
};

let icosphere: Icosphere;
let prevTesselations: number = 8;
let time: number = 0;

function loadScene() {
    icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
    icosphere.create();
}

function main() {
    // Initial display for framerate
    const stats = Stats();
    stats.setMode(0);
    stats.domElement.style.position = 'absolute';
    stats.domElement.style.left = '0px';
    stats.domElement.style.top = '0px';
    document.body.appendChild(stats.domElement);

    // Add controls to the gui
    const gui = new DAT.GUI();
    gui.add(controls, 'tesselations', 0, 8).step(1);
    gui.add(controls, 'Load Scene');

    // get canvas and webgl context
    const canvas = <HTMLCanvasElement> document.getElementById('canvas');
    const gl = <WebGL2RenderingContext>canvas.getContext('webgl2');

    if (!gl) {
        alert('WebGL 2 not supported!');
    }
    // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
    // Later, we can import `gl` from `globals.ts` to access it
    setGL(gl);

    // Initial call to load scene
    loadScene();

    const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

    const renderer = new OpenGLRenderer(canvas);
    renderer.setClearColor(0.2, 0.2, 0.2, 1);
    gl.enable(gl.DEPTH_TEST);

    const custom = new ShaderProgram([
        new Shader(gl.VERTEX_SHADER, customVertSource),
        new Shader(gl.FRAGMENT_SHADER, customFragSource),
    ]);

    // This function will be called every frame
    function tick() {
        time++;

        camera.update();
        stats.begin();
        gl.viewport(0, 0, window.innerWidth, window.innerHeight);
        renderer.clear();

        if (controls.tesselations != prevTesselations) {
            prevTesselations = controls.tesselations;
            icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
            icosphere.create();
        }

        renderer.render(
            camera,
            custom,
            [
                icosphere,
            ],
            time);

        stats.end();

        // Tell the browser to call `tick` again whenever it renders a new frame
        requestAnimationFrame(tick);
    }

    window.addEventListener('resize',
        function () {
            renderer.setSize(window.innerWidth, window.innerHeight);
            camera.setAspectRatio(window.innerWidth / window.innerHeight);
            camera.updateProjectionMatrix();
        },
        false);

    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();

    // Start the render loop
    tick();
}

main();
