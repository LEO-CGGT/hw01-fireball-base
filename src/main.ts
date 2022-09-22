import {vec3} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import * as THREE from 'three';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import audioFile from '/src/assets/Elden_Ring.mp3';

let audioContext : AudioContext;
let audioElement: HTMLAudioElement;
let frenzyMode: number = 0;
// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 6,
  'Reset Fireball': resetFireBall,
  height: 2.0,
  time: 0.1,
  'Play/Pause Music': playMusic,
  madness: 0.6,
  'The Flame of Frenzy': enableFrenzy,
};

let loader: THREE.AudioLoader = new THREE.AudioLoader();
let listener: THREE.AudioListener = new THREE.AudioListener();
let audio: THREE.Audio = new THREE.Audio(listener);
let fftSize: number = 2048;
let analyzer: THREE.AudioAnalyser;
let songData: Uint8Array;

// audioContext = new AudioContext();
// audioElement = new Audio(audioFile);
// const track = audioContext.createMediaElementSource(audioElement);
// track.connect(audioContext.destination);
// const audioAnalyser = audioContext.createAnalyser();
// audioAnalyser.fftSize = 2048;
// const bufferLength = audioAnalyser.frequencyBinCount;
// const dataArray = new Uint8Array(bufferLength);
// audioAnalyser.getByteFrequencyData(dataArray);
// track.connect(audioAnalyser);
// audioElement.play();


function loadSong() {
  if (audio.isPlaying) audio.stop();
  loader.load(audioFile, function (buffer: any) {
    audio.setBuffer(buffer);
    audio.setLoop(true);
    audio.play();
  });
  analyzer = new THREE.AudioAnalyser(audio, fftSize);
  songData = analyzer.getFrequencyData();
}

let icosphere: Icosphere;
let icosphere2: Icosphere;
let square: Square;
let prevTesselations: number = 5;

function resetFireBall()
{
  controls.tesselations = 5;
  controls.height = 2.0;
  controls.time = 0.1;
  controls.madness = 0.6;
  frenzyMode = 0;
}

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  icosphere2 = new Icosphere(vec3.fromValues(0, 0, 10.0), 1, controls.tesselations);
  icosphere2.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();

}

function enableFrenzy()
{
  if (frenzyMode == 0)
  {
    frenzyMode = 1;
    controls.height = 2.5;
    controls.madness = 0.7;
    controls.time = 0.3;
  }
  else
  {
    frenzyMode = 0; 
    controls.height = 2;
    controls.time = 0.1;
    controls.madness = 0.6;

  }
}


function playMusic() {
  // if (audioElement.paused){
  //   audioElement.play();
  // }
  // else
  // {
  //   audioElement.pause();
  // }
  loadSong();
}

function getAverage(data: Uint8Array)
{
  var total = 0;
  data.forEach(function(d)
  {
      total+=d;
  });
  return total / data.length;
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  analyzer = new THREE.AudioAnalyser(audio, fftSize);
  songData = analyzer.getFrequencyData();
  loader.load(audioFile, function (buffer: any) {
    audio.setBuffer(buffer);
    audio.setLoop(true);
  });


  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'Reset Fireball');
  gui.add(controls, 'Play/Pause Music');
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'height', 0, 4).step(0.1).name("Flame Height").listen();
  gui.add(controls,'time',0, 2).step(0.1).name("Movement Speed").listen();
  gui.add(controls, 'madness', 0.01, 0.90).step(0.01).name("Madness").listen();
  gui.add(controls, 'The Flame of Frenzy');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();
  //loadSong();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));
  const backgroundCamera = new Camera(vec3.fromValues(0, 0, -1), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);
  gl.depthFunc(gl.LEQUAL);
  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/eyeball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/eyeball-frag.glsl')),
  ]);
  const fireball = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);
  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/background-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/background-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    //analyzer = new THREE.AudioAnalyser(audio, fftSize);
    songData = analyzer.getFrequencyData();
    
    var lowerHalfArray = songData.slice(0, (songData.length/6) - 1);
    var upperHalfArray = 
    songData.slice((songData.length/6) - 1, songData.length - 1);

    let low: number = getAverage(lowerHalfArray) /lowerHalfArray.length ;
    let high: number = getAverage(upperHalfArray) /upperHalfArray.length;
    //console.log(high);
    // for(var i = 0; i < songData.length; i++)
    // {
    //   if (i < songData.length / 5.0 )
    //   {
    //       low += songData[i]/256.0;
    //   }
    //   else
    //   {
    //       high += songData[i]/256.0
    //   }
    // }
    
    // low /= songData.length / 5.0;
    // high /= songData.length * 4.0 / 5.0;
    var time = controls.time + high * 12.0;
    var height = controls.height + low * 1.5;
    var madness = controls.madness + low * 0.01;
    if (frenzyMode == 0)
    camera.update();
    else
    camera.reset();

    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    renderer.setSize(window.innerWidth, window.innerHeight);

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    gl.disable(gl.DEPTH_TEST);
    renderer.render(backgroundCamera, background, [square],  height, time, madness, frenzyMode);
    gl.enable(gl.DEPTH_TEST);
    renderer.render(camera, fireball, [icosphere],  height, time, madness, frenzyMode);
    
    if (frenzyMode == 1)
    {
      //gl.disable(gl.DEPTH_TEST);
      gl.enable(gl.BLEND);
      gl.enable(gl.SRC_ALPHA);
      gl.enable( gl.ONE_MINUS_SRC_ALPHA);
      gl.enable(gl.BLEND_SRC_ALPHA);

      renderer.render(camera, flat, [icosphere2],height, time, madness, frenzyMode);
      //gl.enable(gl.DEPTH_TEST);
    }  
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
