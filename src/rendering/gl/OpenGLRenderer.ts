import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  timeCount: number = 0;
  prevTime: number = Date.now();
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, colorVec: Array<number>, height: number, timeMult: number) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = vec4.fromValues(colorVec[0], colorVec[1], colorVec[2], colorVec[3] )

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(color);
    this.timeCount += timeMult*(Date.now() - this.prevTime);
    prog.setTime( this.timeCount);
    prog.setHeight(height);
    prog.setCanvasSize(this.canvas.width, this.canvas.height);
    console.log(this.timeCount);

    this.prevTime = Date.now();
    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
