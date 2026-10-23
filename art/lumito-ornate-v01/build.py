"""Ornate Lumito concept art; isolated Blender scene, no gameplay integration."""
from pathlib import Path
import bpy, sys, math
ROOT=Path(__file__).resolve().parents[2]; OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'skills/hac-creature-modeler/scripts'))
from creature_geometry import CreatureKit, make_material, export_fbx_collection
from render_review import render_review
scene=bpy.data.scenes.new('Lumito_Ornate_Review_v01'); bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1
c=bpy.data.collections.new('Lumito_Ornate_Base'); scene.collection.children.link(c)
k=CreatureKit(c); root=k.empty('Lumito_Ornate_Root')
cyan=make_material('Ornate_Cyan',(12,211,245),'Main')
teal=make_material('Ornate_Teal',(10,111,158),'Accent')
white=make_material('Ornate_Porcelain',(240,253,255),'Armor')
gold=make_material('Ornate_Gold',(255,199,79),'Trim','ToyMetal')
ink=make_material('Ornate_Ink',(10,22,40),'Ink')
glow=make_material('Ornate_Crystal',(53,233,255),'Glow','ToyGlow')
def box(n,d,p,m,b=.04,parent=root,rot=(0,0,0)):
 return k.frustum(n,d[0],d[1],d[0],d[1],d[2],location=p,material=m,bevel=b,parent=parent,rotation=rot)
body=k.empty('Body_Pivot',(0,0,.30),parent=root)
k.frustum('Torso',.85,.66,1.02,.76,.91,material=cyan,bevel=.10,parent=body)
for side,x in [('L',-.40),('R',.40)]:
 foot=k.empty('Foot_'+side+'_Pivot',(x,-.09,0),parent=root)
 box('Sole_'+side,(.56,.65,.06),(0,0,0),teal,.03,foot)
 k.frustum('Foot_'+side,.52,.60,.35,.39,.22,location=(0,0,.06),material=cyan,bevel=.04,parent=foot)['FootSide']=side
 box('GoldToe_'+side,(.54,.30,.06),(0,-.17,.06),gold,.02,foot)
 k.frustum('WhiteToe_'+side,.42,.28,.30,.20,.15,location=(0,-.19,.12),material=white,bevel=.025,parent=foot)
 arm=k.empty('Arm_'+side+'_Pivot',(x*1.50,0,.96),rotation=(0,18 if side=='R' else -18,0),parent=root)
 box('Arm_'+side,(.31,.43,.48),(0,0,-.42),cyan,.07,arm)
 box('ShoulderGold_'+side,(.43,.48,.18),(0,0,-.05),gold,.06,arm)
 box('ShoulderWhite_'+side,(.33,.40,.18),(0,-.07,-.02),white,.05,arm)
 box('Bracer_'+side,(.35,.12,.22),(0,-.23,-.35),white,.045,arm)
head=k.empty('Head_Pivot',(0,-.02,1.24),rotation=(0,-5,0),parent=root)
k.loft('Head',[(0,1.20,1.01,0,0),(.20,1.70,1.24,0,0),(.82,1.74,1.24,0,0),(1.00,1.32,.94,0,0)],material=cyan,bevel=.11,parent=head)
box('OpenEye',(.23,.06,.29),(-.38,-.64,.40),ink,.03,head)
box('Catchlight',(.07,.025,.08),(-.40,-.677,.59),white,.008,head)
box('Wink',(.25,.07,.085),(.36,-.65,.45),ink,.025,head,rot=(0,0,-5))
k.frustum('Muzzle',.52,.09,.94,.09,.29,location=(0,-.60,.07),material=white,bevel=.035,parent=head)
box('Mouth',(.36,.05,.065),(0,-.67,.18),ink,.015,head)
k.frustum('Tooth',.04,.03,.10,.03,.09,location=(.09,-.70,.10),material=white,bevel=.005,parent=head)
ear=k.empty('Ear_L_Pivot',(-.53,0,.90),parent=head)
k.loft('Ear_L',[(0,.40,.30,0,0),(.43,.35,.27,0,0),(.70,.09,.14,0,0)],material=cyan,bevel=.04,parent=ear)
box('EarInner_L',(.15,.04,.38),(0,-.15,.12),teal,.025,ear)
ear=k.empty('Ear_R_Pivot',(.53,0,.89),rotation=(0,25,0),parent=head)
box('Ear_R_Base',(.34,.30,.30),(0,0,0),cyan,.04,ear)
box('Ear_R_Fold',(.35,.33,.29),(.08,-.06,.24),cyan,.04,ear,rot=(30,0,0))
box('Crest',(.30,.08,.71),(0,.61,.30),teal,.03,head)
for y in [-.13,.10,.33]: k.stud('CrestStud',(0,y,1.00),radius=.08,height=.05,material=teal,parent=head)
# Nested diamond plates create crisp ivory/gold armor and luminous crystal centers.
def jewel(n,p,w,h,parent=root,rot=(0,0,0)):
 j=k.empty(n+'_Pivot',p,rot,parent)
 k.diamond(n+'_White',w,.13,h*.5,h*.5,material=white,parent=j)
 k.diamond(n+'_Core',w*.63,.14,h*.35,h*.35,location=(0,-.055,0),material=glow,parent=j)
 return j
k.diamond('ChestGold',.90,.20,.43,.40,location=(0,-.40,.78),material=gold)
k.diamond('ChestWhite',.77,.16,.38,.35,location=(0,-.46,.80),material=white)
jewel('Heart',(0,-.57,.91),.42,.58)
k.diamond('BackArmor',.67,.18,.36,.33,location=(0,.43,.84),material=gold)
jewel('BackCrystal',(0,.55,.89),.44,.45,rot=(0,0,180))
k.diamond('Crown',.31,.22,.12,.28,location=(0,-.17,1.03),material=gold,parent=head)
jewel('CrownGem',(0,-.30,1.16),.14,.23,parent=head)
halo=k.empty('Halo_Pivot',(0,.42,2.18),parent=root)
k.segmented_arc('HaloGold',1.00,.085,.10,arc_degrees=300,segments=10,material=gold,parent=halo)
for angle in [-70,70,-125,125]:
 a=math.radians(angle)
 box('HaloClasp',(.15,.15,.23),(math.sin(a),0,math.cos(a)),white,.02,halo,rot=(0,angle,0))
for side in [-1,1]:
 wing=k.empty('Wing_Pivot',(side*.62,.29,1.05),rotation=(0,side*45,0),parent=root)
 k.diamond('WingGold',.31,.18,.12,.67,material=gold,parent=wing)
 jewel('WingCrystal',(0,-.04,.60),.40,.93,parent=wing)
 jewel('OrbitSide',(side*1.45,.15,1.98),.17,.48)
 jewel('OrbitLow',(side*1.25,-.02,.88),.30,.20,rot=(0,side*18,0))
jewel('OrbitTop',(0,.42,3.37),.23,.66)
box('Neck',(.46,.45,.25),(0,0,1.10),cyan,.05)
for side,x in [('L',-.34),('R',.34)]:
 box('Leg_'+side,(.32,.37,.26),(x,0,.20),cyan,.04)
for o in c.objects:
 if o.name.startswith('WingCrystal_') and o.type=='MESH': o.scale.y=1.8
bpy.context.view_layer.update()
export_fbx_collection(c,OUT/'Lumito_Ornate_v01.fbx')
bpy.data.libraries.write(str(OUT/'Lumito_Ornate_v01.blend'),{scene},fake_user=True)
result=render_review(c.name,OUT/'review','Lumito_Ornate_v01')
