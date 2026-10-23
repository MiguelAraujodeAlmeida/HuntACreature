"""Rebuild Chicken concept art in an isolated Blender scene."""
from pathlib import Path
import sys, bpy
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'skills/hac-creature-modeler/scripts'))
from creature_geometry import CreatureKit, make_material, export_fbx_collection
OUT = Path(__file__).resolve().parent
scene = bpy.data.scenes.new('Chicken_Review_v01')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
collection = bpy.data.collections.new('Chicken_Base')
scene.collection.children.link(collection)
k = CreatureKit(collection)
root = k.empty('Chicken_Root')
cream = make_material('Chicken_Cream',(247,231,204),'Main')
white = make_material('Chicken_Ivory',(255,248,229),'Secondary')
red = make_material('Chicken_Coral',(235,52,67),'Accent')
gold = make_material('Chicken_Yolk',(255,181,28),'Extra_1')
sole = make_material('Chicken_Sole',(137,79,36),'Extra_2')
ink = make_material('Chicken_Eyes',(21,27,37),'Ink','ToyGloss')
glint = make_material('Chicken_Glint',(255,255,255),'Glint')
def box(name, dims, loc, mat, bevel=.05, parent=root, rot=(0,0,0)):
    return k.frustum(name,dims[0],dims[1],dims[0],dims[1],dims[2],location=loc,material=mat,bevel=bevel,parent=parent,rotation=rot)
body = k.empty('Body_Pivot',(0,0,0.28),parent=root)
k.loft('Body',[(0,1.05,.87,0,0),(.18,1.40,1.12,0,.02),(.70,1.26,1.10,0,.03),(.95,.88,.78,0,0)],bevel=.13,material=cream,parent=body)
k.frustum('Breast',1.04,.08,.82,.08,.65,location=(0,-.49,.10),rotation=(0,0,0),material=white,bevel=.035,parent=body)
head = k.empty('Head_Pivot',(0,-.08,1.20),parent=root)
k.loft('Head',[(0,1.18,1.03,0,0),(.18,1.65,1.35,0,0),(.80,1.65,1.35,0,0),(1.02,1.24,1.02,0,0)],bevel=.13,material=white,parent=head)
for side,x in [('L',-.47),('R',.47)]:
    box('Eye_'+side,(.185,.065,.29),(x,-.687,.37),ink,.035,head)
    box('Glint_'+side,(.065,.025,.075),(x-.025,-.727,.55),glint,.008,head)
k.frustum('Beak',.57,.47,.37,.29,.27,location=(0,-.78,.26),material=gold,bevel=.045,parent=head)
box('Wattle',(.28,.19,.38),(0,-.71,-.12),red,.075,head,(-10,0,0))
# Stepped comb follows the sagittal plane, with broad front and rear lobes.
box('Comb_Front',(.25,.36,.42),(0,-.37,.91),red,.045,head,(-10,0,0))
box('Comb_Crown',(.25,.41,.54),(0,-.04,1.00),red,.045,head)
box('Comb_Rear',(.25,.30,.25),(0,.30,1.00),red,.035,head)
for side,x,angle in [('L',-.616,-15),('R',.616,15)]:
    wing=k.empty('Wing_'+side+'_Pivot',(x,.02,.92),parent=root)
    box('Wing_'+side,(.30,.60,.52),(0,0,-.42),cream,.115,wing,(0,angle,0))
    foot=k.empty('Foot_'+side+'_Pivot',(x*.65,-.08,0),parent=root)
    box('Sole_'+side,(.57,.64,.045),(0,-.04,0),sole,.035,foot)
    obj=k.frustum('Foot_'+side,.53,.60,.33,.35,.19,location=(0,-.04,.045),material=gold,bevel=.035,parent=foot)
    obj['FootSide']=side
    box('Ankle_'+side,(.22,.22,.15),(0,.05,.19),gold,.025,foot)
    k.stud('FootStud_'+side,(0,.09,.24),radius=.07,height=.035,material=gold,parent=foot)
tail=k.empty('Tail_Pivot',(0,.43,.69),parent=root)
for i,(x,angle,length) in enumerate([(-.09,-27,.84),(0,-43,1.08),(.09,-63,.84)]):
    k.frustum('Tail_Feather_'+str(i),.24,.25,.34,.28,length,location=(x,0,0),rotation=(angle,0,0),material=white,bevel=.065,parent=tail)
bpy.context.view_layer.update()
export_fbx_collection(collection, OUT/'Chicken_Base_v01.fbx')
# Write only this scene and its dependencies, leaving the preexisting file intact.
bpy.data.libraries.write(str(OUT/'Chicken_Base_v01.blend'), {scene}, fake_user=True)
result={'scene':scene.name,'objects':len(collection.objects),'output':str(OUT)}

