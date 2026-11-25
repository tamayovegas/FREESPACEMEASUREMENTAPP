// Isolated tests of the HTML's actual controller, without a browser or network.
// Run: node testSymbolicTensors.cjs
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync(__dirname + '/SymbolicTensors.html', 'utf8');
class Element {
  constructor(tag) { this.tagName=tag; this.children=[]; this.listeners={}; this.dataset={}; this.attributes={}; this.hidden=false; this.className=''; this.firstChild={textContent:''}; }
  set innerHTML(value) { this.html=value; this.children=[]; }
  get innerHTML() { return this.html || ''; }
  appendChild(child) { this.children.push(child); }
  setAttribute(name,value) { this.attributes[name]=value; }
  addEventListener(name,callback) { this.listeners[name]=callback; }
  fire(name) { this.listeners[name].call(this); }
  get classList() { return {toggle:(name,on)=>{const classes=new Set(this.className.split(' ').filter(Boolean));on?classes.add(name):classes.delete(name);this.className=[...classes].join(' ');}}; }
}
const ids={};
for(const match of source.matchAll(/id="([^"]+)"/g)) {
  assert(!ids[match[1]], 'duplicate HTML ID'); ids[match[1]]=new Element('div'); ids[match[1]].id=match[1];
}
ids.symmetry.value='reciprocal'; ids.frame.value='material';
const defaults={planGeometry:'Reflection + transmission',planScanKind:'Incidence sweep',planAngleStart:'0',planAngleStop:'60',planAngleCount:'7',planAzimuthStart:'0',planAzimuthStop:'90',planAzimuthCount:'2',planOrientationCount:'1',planFrequencyCount:'1',planPolarization:'2'};
for(const [id,value] of Object.entries(defaults)) ids[id].value=value;
const pages=[...source.matchAll(/<section id="([^"]+)" class="section"( hidden)?>/g)].map(m=>{ids[m[1]].hidden=!!m[2];return ids[m[1]];});
const buttons=[...source.matchAll(/<button[^>]*data-page="([^"]+)"/g)].map(m=>{const el=new Element('button');el.dataset.page=m[1];return el;});
const document={getElementById:id=>{assert(ids[id],`missing ID ${id}`);return ids[id];},createElement:tag=>new Element(tag),querySelectorAll:selector=>selector==='.section'?pages:selector==='nav button'?buttons:assert.fail(selector)};
const browserWindow={scrollTo(){}};
vm.runInNewContext(source.match(/<script>([\s\S]*?)<\/script>/)[1], {document,window:browserWindow});
const entries=()=>ids.tensorCards.children.flatMap(c=>c.children.find(e=>e.className==='matrix').children);
function set(id,value){ids[id].value=value;ids[id].fire('change');}
assert.equal(entries().length,27);
for(let tensor=0;tensor<3;tensor++) {
  const a=entries().slice(tensor*9,tensor*9+9);
  assert.equal(a[1].innerHTML,a[3].innerHTML);assert.equal(a[2].innerHTML,a[6].innerHTML);assert.equal(a[5].innerHTML,a[7].innerHTML);
}
set('symmetry','general');assert.notEqual(entries()[1].innerHTML,entries()[3].innerHTML);
set('symmetry','principal');assert.equal(entries().filter(e=>e.innerHTML==='0').length,18);
set('frame','laboratory');assert.equal(entries().filter(e=>e.innerHTML==='0').length,0);
assert(entries()[1].innerHTML.includes('<sup>L</sup>'));
set('symmetry','isotropic');assert.equal(entries().filter(e=>e.innerHTML==='0').length,18);
entries()[10].fire('click');assert(ids.componentMeaning.textContent.includes('structurally zero'));
set('symmetry','general');entries()[14].fire('click');assert.equal(ids.inputComponent.textContent,'H_z');assert.equal(ids.outputComponent.textContent,'B_y');
entries()[25].fire('click');assert.equal(ids.inputComponent.textContent,'E_y');assert.equal(ids.outputComponent.textContent,'J_z');
for(const button of buttons){button.fire('click');assert.deepEqual(pages.filter(p=>!p.hidden).map(p=>p.id),[button.dataset.page]);}
assert.equal(buttons.length,6);
assert(!/<script[^>]+src=|<link[^>]+stylesheet/.test(source), 'workspace must remain offline');
const api=browserWindow.QuasiOpticalTensors;
let plan=api.computePlan({...api.getPlanConfig(),angleCount:5,azimuthCount:3,orientationCount:2,frequencyCount:101,polarizationChannels:4});
assert.equal(plan.nConfigurations,30);assert.equal(plan.nTraceAcquisitions,240);assert.equal(plan.nComplexSamples,24240);assert.equal(plan.nSParameterPairs,12120);assert.equal(plan.nCoPolarizedPairs,6060);assert(plan.nrwEligible);
plan=api.computePlan({...api.getPlanConfig(),geometry:'Reflection arc'});assert.equal(plan.nSParameterPairs,0);assert(!plan.scalarRetrievalEligible);
plan=api.computePlan({...api.getPlanConfig(),scanKind:'Rx observation arc'});assert.equal(plan.nSParameterPairs,0);assert(!plan.nrwEligible);
assert.throws(()=>api.computePlan({...api.getPlanConfig(),angleStopDeg:90}),/Incidence/);
assert.throws(()=>api.computePlan({...api.getPlanConfig(),angleCount:1.2}),/whole/);
api.setPlanConfig({angleStartDeg:0,angleStopDeg:60,angleCount:1,azimuthStartDeg:25,azimuthStopDeg:90,azimuthCount:1});
const single=api.computePlan(api.getPlanConfig());assert(single.nrwEligible);assert.equal(single.config.angleStopDeg,0);assert.equal(single.config.azimuthStopDeg,25);assert(ids.planAngleStop.disabled);assert(ids.planAzimuthStop.disabled);
const bridge={Data:{action:'sync',setup:{mode:'Transmission',frequencyGHz:10,incidenceDeg:25,azimuthDeg:30,thicknessMM:3}},addEventListener(name,callback){this.listener=callback;}};
api.connect(bridge);assert(!ids.useSetup.disabled);assert(ids.setupSummary.textContent.includes('α = 25°'));
assert(ids.setupSummary.textContent.includes('f = 10 GHz'));
bridge.Data.setup.frequencyLowGHz=8.2;bridge.Data.setup.frequencyHighGHz=12.4;bridge.listener();
assert(ids.setupSummary.textContent.includes('f center = 10 GHz (band 8.2–12.4 GHz)'));
ids.useSetup.fire('click');assert.equal(ids.planGeometry.value,'Transmission line');assert.equal(ids.planAngleStart.value,'25');assert.equal(ids.planAngleCount.value,'1');
ids.exportMatrixPNG.fire('click');assert.equal(bridge.Data.action,'exportMatrices');assert.equal(bridge.Data.format,'png');assert.equal(bridge.Data.planConfig.geometry,'Transmission line');assert.equal(bridge.Data.symmetry,'general');
const svg=api.matrixSVG(api.computePlan(api.getPlanConfig()));assert(svg.includes('unassigned material properties'));assert(svg.includes('ε_r,xx^L'));assert(svg.includes('same')===false);assert(!svg.includes('undefined'));
console.log('Symbolic controller passed: 27 entries, all assumptions/frames, component maps, six topic pages, linked acquisition planner, sample counts, export bridge, symbolic SVG, offline assets.');
