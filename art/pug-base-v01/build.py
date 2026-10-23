"""Pug concept, isolated scene; run with Blender Python. Front -Y, up +Z."""
from pathlib import Path
import sys, bpy, math
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'skills/hac-creature-modeler/scripts'))
from creature_geometry import CreatureKit, make_material, export_fbx_collection
from render_review import render_review
OUT=Path(__file__).resolve().parent
scene=bpy.data.scenes.new('Pug_Review_v01'); bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1
c=bpy.data.collections.new('Pug_Base'); scene.collection.children.link(c)
k=CreatureKit(c); root=k.empty('Pug_Root')
tan=make_material('Pug_Biscuit',(235,202,153),'Main')
cream=make_material('Pug_Cream',(255,237,199),'Secondary')
brown=make_material('Pug_Chocolate',(100,77,69),'Accent')
ear=make_material('Pug_Ear',(119,93,84),'Accent')
black=make_material('Pug_Ink',(23,27,32),'Ink','ToyGloss')
pink=make_material('Pug_Tongue',(239,127,143),'Extra_1')
white=make_material('Pug_Glint',(255,255,255),'Glint')
def box(n,d,p,m,b=.05,parent=root,rot=(0,0,0)):
 return k.frustum(n,d[0],d[1],d[0],d[1],d[2],location=p,material=m,bevel=b,parent=parent,rotation=rot)
body=k.empty('Body_Pivot',(0,.16,.43),parent=root)
k.loft('Body',[(0,1.01,1.35,0,0),(.18,1.25,1.55,0,0),(.65,1.17,1.49,0,0),(.82,.91,1.20,0,0)],material=tan,bevel=.10,parent=body)
box('Chest',(.72,.12,.43),(0,-.60,.61),cream,.05)
for label,x,y,phase in [('FL',-.45,-.38,'L'),('FR',.45,-.38,'R'),('BL',-.45,.69,'R'),('BR',.45,.69,'L')]:
 pivot=k.empty(label+'_Leg_Pivot',(x,y,.69),parent=root)
 k.frustum(label+'_Leg',.35,.37,.41,.42,.55,location=(0,0,-.58),material=tan,bevel=.055,parent=pivot)
 paw=box(label+'_Paw',(.44,.48,.14),(0,-.045,-.69),brown,.045,pivot); paw['FootSide']=phase
 # Two large toe divisions, readable at gameplay scale.
 for i in [-1,1]:
  box(label+'_Toe'+str(i),(.13,.10,.075),(i*.10,-.265,-.66),ear,.018,pivot)
head=k.empty('Head_Pivot',(0,-.38,1.10),rotation=(0,-3,0),parent=root)
k.loft('Head',[(0,1.20,1.02,0,0),(.22,1.70,1.30,0,0),(.95,1.65,1.30,0,0),(1.15,1.19,.97,0,0)],material=tan,bevel=.13,parent=head)
for side,x,angle in [('L',-.54,-8),('R',.54,8)]:
 box('Eye_'+side,(.23,.085,.34),(x,-.67,.39),black,.035,head,(0,angle,0))
 box('Glint_'+side,(.078,.025,.09),(x-.035,-.722,.61),white,.009,head)
 # Drooping ears anchored over the upper corner of the head.
 box('Ear_'+side,(.46,.58,.27),(x*1.22,-.03,.86),ear,.08,head,(22,angle*2.8,0))
k.loft('Muzzle',[(0,.96,.28,0,0),(.18,1.02,.40,0,0),(.49,.57,.32,0,.025),(.58,.38,.24,0,.035)],location=(0,-.70,.07),material=brown,bevel=.065,parent=head)
box('Mouth',(.43,.055,.14),(0,-.918,.09),black,.035,head)
box('Tongue',(.22,.11,.18),(0,-.96,.045),pink,.055,head,(-12,0,0))
k.frustum('Nose',.18,.15,.30,.20,.14,location=(0,-.83,.45),material=black,bevel=.035,parent=head)
tail=k.empty('Tail_Pivot',(0,.83,.96),parent=root)
box('Tail_Stem',(.24,.38,.25),(0,0,0),tan,.065,tail,(25,0,0))
# Curl in the sagittal plane so its opening reads in profile.
k.segmented_arc('Tail_Curl',.29,.18,.25,arc_degrees=310,segments=9,location=(0,.29,.32),rotation=(0,0,90),material=tan,bevel=.02,parent=tail)
for x in [-.12,.12]:
 k.stud('BackStud', (x,.61,1.245),radius=.075,height=.045,material=tan,parent=root)
bpy.context.view_layer.update()
export_fbx_collection(c,OUT/'Pug_Base_v01.fbx')
bpy.data.libraries.write(str(OUT/'Pug_Base_v01.blend'),{scene},fake_user=True)
result=render_review(c.name,OUT/'review','Pug_Base_v01')
