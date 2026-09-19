import {vec3, vec4} from 'gl-matrix';
import Stats from 'stats-js';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import skyVertSource from './shaders/sky-vert.glsl?raw';
import skyFragSource from './shaders/sky-frag.glsl?raw';

import customVertSource from './shaders/custom-vert.glsl?raw';
import customFragSource from './shaders/custom-frag.glsl?raw';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
    octaves: 4,
    timeScale: 0.002,
    color: [255.0, 12.75, 0.765, 1.0],
    tesselations: 8,
    'Reset': loadScene, // A function pointer, essentially
};

const gui = new DAT.GUI();

let quad: Square;
let icosphere: Icosphere;
let prevTesselations: number = 8;
let time: number = 0;

function loadScene() {
    controls.octaves = 4;
    controls.timeScale = 0.002;
    controls.color = [255.0, 12.75, 0.765, 1.0];
    controls.tesselations = 8;
    gui.updateDisplay();

    icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
    icosphere.create();

    quad = new Square(vec3.fromValues(0, 0, 0));
    quad.create();
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
    gui.add(controls, 'tesselations', 0, 8).step(1);
    gui.add(controls, 'octaves').min(0).max(6).step(1);
    gui.addColor(controls, 'color');
    gui.add(controls, 'timeScale').min(0.0).max(0.004).step(0.0001);
    gui.add(controls, 'Reset');

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

    const customShader = new ShaderProgram([
        new Shader(gl.VERTEX_SHADER, customVertSource),
        new Shader(gl.FRAGMENT_SHADER, customFragSource),
    ]);

    const skyShader = new ShaderProgram([
        new Shader(gl.VERTEX_SHADER, skyVertSource),
        new Shader(gl.FRAGMENT_SHADER, skyFragSource),
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

        let color = vec4.fromValues(controls.color[0] / 255, controls.color[1] / 255, controls.color[2] / 255, controls.color[3]);

        gl.disable(gl.DEPTH_TEST);
        renderer.skyRender(camera, skyShader, quad, time, controls.timeScale, controls.octaves, color);

        gl.enable(gl.DEPTH_TEST);
        renderer.customRender(
            camera,
            customShader,
            color,
            [
                icosphere,
            ],
            time,
            controls.timeScale,
            controls.octaves);

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
