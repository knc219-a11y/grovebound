#!/usr/bin/env python3
"""Build a fused, colored boar surface and skin weights. Requires numpy/scikit-image."""
import gzip
import json
import math
from pathlib import Path
import numpy as np
from skimage.measure import marching_cubes

STEP = .065
UPPER, LOWER = .46, .45
ROOTS = [(x, .91, side * .38) for side in (-1, 1) for x in (.53, -.68)]
BEATS = [.75, .5, .25, 0]


def foot(beat):
    half = .8 * .64 / 2
    if beat < .64: return np.array([half - .8 * beat, .12, 0.])
    t = (beat - .64) / .36
    m = -.8 * .36
    x = (2*t**3-3*t*t+1)*(-half)+(t**3-2*t*t+t)*m+(-2*t**3+3*t*t)*half+(t**3-t*t)*m
    return np.array([x, .12 + math.sin(math.pi*t)**2*.15, 0.])


def knee(root, target, sign):
    d = target-root
    length = np.linalg.norm(d)
    axis = d/length
    along = (UPPER**2-LOWER**2+length**2)/(2*length)
    perpendicular = np.array([-axis[1], axis[0], 0.])*sign
    return root+axis*along+perpendicular*math.sqrt(UPPER**2-along**2)


rest = []
for i, (root, beat) in enumerate(zip(ROOTS, BEATS)):
    r = np.array(root, dtype=float)
    target = foot(beat); target[[0, 2]] += r[[0, 2]]
    joint = knee(r, target, -1 if i % 2 == 0 else 1)
    rest.extend([(r, joint), (joint, target)])

axes = [np.arange(-1.35, 1.96, STEP), np.arange(-.04, 2.03, STEP), np.arange(-.73, .74, STEP)]
p = np.stack(np.meshgrid(*axes, indexing='ij'), axis=-1)


def ellipsoid(center, radius):
    r = np.array(radius)
    q = (p-center)/r
    return (np.linalg.norm(q, axis=-1)-1)*min(r)


def smooth_union(a, b, softness):
    h = np.clip(.5+.5*(b-a)/softness, 0, 1)
    return b*(1-h)+a*h-softness*h*(1-h)


def capsule(a, b, radius_a, radius_b):
    v = b-a
    t = np.clip(np.sum((p-a)*v, axis=-1)/np.dot(v,v), 0, 1)
    radius = radius_a+(radius_b-radius_a)*t
    return np.linalg.norm(p-a-t[...,None]*v,axis=-1)-radius


field = ellipsoid((-.23, 1.16, 0), (1.00, .65, .56))
for center, radius, blend in [((-.67, 1.10, 0),(.62,.63,.56),.20),((.42,1.16,0),(.61,.55,.55),.18),((.94,1.22,0),(.63,.65,.47),.19),((1.40,.96,0),(.43,.28,.33),.16)]:
    field = smooth_union(field, ellipsoid(center,radius), blend)
for i, (a, b) in enumerate(rest):
    field = smooth_union(field, capsule(a,b,.23 if i%2==0 else .155,.155 if i%2==0 else .105), .10 if i%2==0 else .065)
vertices, faces, normals, _ = marching_cubes(field.astype(np.float32), 0, spacing=(STEP,)*3)
vertices += np.array([a[0] for a in axes])
# Derive outward normals directly from the same scalar field to avoid winding assumptions.
from scipy.ndimage import map_coordinates
coords = ((vertices-np.array([a[0] for a in axes]))/STEP).T
normals = np.column_stack([map_coordinates(g,coords,order=1,mode='nearest') for g in np.gradient(field,STEP)])
normals /= np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-9)
# Match Godot clockwise front faces to outward normals.
tri = vertices[faces]
if np.mean(np.sum(np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0])*normals[faces].mean(axis=1),axis=1)) > 0:
    faces = faces[:,[0,2,1]]  # Godot uses clockwise fronts.

weights = np.zeros((len(vertices),9))
weights[:,0] = np.clip((vertices[:,1]-.52)/.47,0,1)**2*2.5
distances=[]
for i,(a,b) in enumerate(rest):
    v=b-a
    t=np.clip((vertices-a)@v/np.dot(v,v),0,1)
    distance=np.linalg.norm(vertices-a-t[:,None]*v,axis=1)
    weights[:,i+1]=np.exp(-(distance/.19)**2)
    distances.append(distance)
weights[:,0]+=2.0*np.clip((np.min(distances,axis=0)-.20)/.20,0,1)**2
# Keep only four strongest influences, including a torso influence when appropriate.
order=np.argsort(weights,axis=1)[:,-4:]
selected=np.take_along_axis(weights,order,axis=1)
selected/=np.maximum(selected.sum(axis=1,keepdims=True),1e-10)

# Stable painted fur color variation; vertex colors move with the surface.
base=np.array([.61,.365,.18])
colors=np.tile(base,(len(vertices),1))
shade=.87+.17*np.clip((vertices[:,1]-.5)/1.2,0,1)
colors*=shade[:,None]
rng=np.random.default_rng(219)
for _ in range(44):
    x,y=rng.uniform(-1.0,.68),rng.uniform(.82,1.77)
    dx=(vertices[:,0]-x);dy=(vertices[:,1]-y)
    u=(dx*.87-dy*.49)/.16;v=(dx*.49+dy*.87)/.055
    patch=np.clip((1-np.abs(u)-np.abs(v))*2.5,0,1)*(np.abs(vertices[:,2])>.24)
    colors*=1-patch[:,None]*rng.uniform(.04,.10)
face=np.clip((vertices[:,0]-.65)/.45,0,1)
colors*=1+face[:,None]*.065
colors=np.clip(colors,0,1)
# Obtain tuft roots from the fused surface so the bristles never float.
back=[]
for x in [-.94,-.70,-.44,-.15,.14,.40]:
    ix=np.argmin(np.abs(axes[0]-x));iz=np.argmin(np.abs(axes[2]))
    inside=np.flatnonzero(field[ix,:,iz]<0)
    back.append([float(x),float(axes[1][inside[-1]]),0.])

round_array=lambda a:np.round(a,6).tolist()
data={"vertices":round_array(vertices),"normals":round_array(normals),"colors":round_array(colors),"indices":faces.reshape(-1).tolist(),"bones":order.tolist(),"weights":round_array(selected),"rest_bones":[[a.tolist(),b.tolist()] for a,b in rest],"back":back}
out=Path(__file__).resolve().parent.parent/'experiments/boar3d/boar_surface.json.gz'
with gzip.GzipFile(filename=str(out),mode='wb',mtime=0) as file:
    file.write(json.dumps(data,separators=(',',':')).encode())
print(f'SURFACE PASS: {len(vertices)} vertices, {len(faces)} triangles, {out.stat().st_size:,} bytes')
