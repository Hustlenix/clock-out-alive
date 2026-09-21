"""Original raster artwork and audio for CLOCK OUT ALIVE.

All shapes, compositions, marks, and synthesis recipes authored for this game.
Run: python source_art/create_assets.py
Needs Pillow and NumPy. No stock art, downloaded samples, or generative images.
Low-resolution canvases deliberately use flat, uneven fills and hard edges.
Layer PNGs are saved under source_art/layers; runtime copies under assets/art.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math, random, wave, json
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets' / 'art'
AUDIO = ROOT / 'assets' / 'audio'
LAYERS = ROOT / 'source_art' / 'layers'
for directory in (ART, AUDIO, LAYERS): directory.mkdir(parents=True, exist_ok=True)
random.seed(333)
INK = '#101624'
DEEP = '#080d18'
CREAM = '#d5cdb0'
YELLOW = '#c7b866'
GREEN = '#a5bf8b'
RED = '#af524d'
BLUE = '#536e80'
PURPLE = '#9c82b4'
PALETTE = [INK, DEEP, CREAM, YELLOW, GREEN, RED, BLUE, PURPLE]
manifest = {}

# A deliberately unpolished one-stroke lettering alphabet; these are our own
# strokes, not a downloaded icon or font library. Coordinates live on a 5x7 grid.
GLYPHS = {
 'A': [[(0,7),(2,0),(4,7)],[(1,4),(3,4)]],
 'B': [[(0,7),(0,0),(3,0),(4,1),(4,2),(3,3),(0,3)],[(2,3),(4,4),(4,6),(3,7),(0,7)]],
 'C': [[(4,1),(3,0),(1,0),(0,1),(0,6),(1,7),(3,7),(4,6)]],
 'D': [[(0,7),(0,0),(2,0),(4,2),(4,5),(2,7),(0,7)]],
 'E': [[(4,0),(0,0),(0,7),(4,7)],[(0,3),(3,3)]],
 'F': [[(4,0),(0,0),(0,7)],[(0,3),(3,3)]],
 'G': [[(4,1),(3,0),(1,0),(0,2),(0,5),(1,7),(4,7),(4,4),(2,4)]],
 'H': [[(0,0),(0,7)],[(4,0),(4,7)],[(0,3),(4,3)]],
 'I': [[(0,0),(4,0)],[(2,0),(2,7)],[(0,7),(4,7)]],
 'J': [[(0,0),(4,0),(4,6),(3,7),(1,7),(0,6)]],
 'K': [[(0,0),(0,7)],[(4,0),(0,4),(4,7)]],
 'L': [[(0,0),(0,7),(4,7)]],
 'M': [[(0,7),(0,0),(2,3),(4,0),(4,7)]],
 'N': [[(0,7),(0,0),(4,7),(4,0)]],
 'O': [[(1,0),(3,0),(4,1),(4,6),(3,7),(1,7),(0,6),(0,1),(1,0)]],
 'P': [[(0,7),(0,0),(3,0),(4,1),(4,3),(3,4),(0,4)]],
 'Q': [[(1,0),(3,0),(4,1),(4,5),(2,7),(0,6),(0,1),(1,0)],[(2,5),(5,8)]],
 'R': [[(0,7),(0,0),(3,0),(4,1),(4,3),(3,4),(0,4)],[(2,4),(4,7)]],
 'S': [[(4,1),(3,0),(1,0),(0,1),(0,3),(4,4),(4,6),(3,7),(1,7),(0,6)]],
 'T': [[(0,0),(4,0)],[(2,0),(2,7)]],
 'U': [[(0,0),(0,6),(1,7),(3,7),(4,6),(4,0)]],
 'V': [[(0,0),(2,7),(4,0)]],
 'W': [[(0,0),(1,7),(2,4),(3,7),(4,0)]],
 'X': [[(0,0),(4,7)],[(4,0),(0,7)]],
 'Y': [[(0,0),(2,3),(4,0)],[(2,3),(2,7)]],
 'Z': [[(0,0),(4,0),(0,7),(4,7)]],
 '0': [[(1,0),(3,0),(4,1),(4,6),(3,7),(1,7),(0,6),(0,1),(1,0)],[(0,6),(4,1)]],
 '1': [[(0,2),(2,0),(2,7)],[(0,7),(4,7)]],
 '2': [[(0,1),(1,0),(3,0),(4,1),(4,3),(0,7),(4,7)]],
 '3': [[(0,0),(4,0),(2,3),(4,4),(4,6),(3,7),(0,7)]],
 '4': [[(3,7),(3,0),(0,4),(4,4)]],
 '5': [[(4,0),(0,0),(0,3),(3,3),(4,4),(4,6),(3,7),(0,7)]],
 '6': [[(4,0),(1,0),(0,3),(0,6),(1,7),(3,7),(4,6),(4,4),(0,4)]],
 '7': [[(0,0),(4,0),(1,7)]],
 '8': [[(1,0),(3,0),(4,1),(3,3),(1,3),(0,1),(1,0)],[(1,3),(0,4),(0,6),(1,7),(3,7),(4,6),(4,4),(3,3)]],
 '9': [[(4,3),(0,3),(0,1),(1,0),(3,0),(4,1),(4,6),(3,7),(0,7)]],
 ':': [[(2,2),(2,2.4)],[(2,5),(2,5.4)]],
 '-': [[(0,3),(4,3)]], '/': [[(0,7),(4,0)]],
 '.': [[(2,7),(2,7.3)]], '!': [[(2,0),(2,5)],[(2,7),(2,7.3)]],
 '?': [[(0,1),(1,0),(3,0),(4,1),(4,2),(2,4),(2,5)],[(2,7),(2,7.3)]],
 '+': [[(0,3),(4,3)],[(2,1),(2,5)]],
}

def canvas(w=640,h=360,color=(0,0,0,0)):
    return Image.new('RGBA',(w,h),color)

def draw(im): return ImageDraw.Draw(im)

def line(im,pts,fill=INK,width=2):
    draw(im).line(pts,fill=fill,width=width,joint='curve')

def poly(im,pts,fill,outline=INK,width=2):
    d=draw(im); d.polygon(pts,fill=fill)
    if outline: d.line(pts+[pts[0]],fill=outline,width=width,joint='curve')

def rect(im,box,fill,outline=None,width=1): draw(im).rectangle(box,fill,outline,width)
def ellipse(im,box,fill,outline=INK,width=2): draw(im).ellipse(box,fill,outline,width)

def letter(im,text,xy,size=2,color=CREAM,width=None,spacing=1,rough=True):
    x,y=xy; width=width or max(1,int(size*.75))
    rng=random.Random(33+sum(map(ord,text)))
    for ch in text.upper():
        dy=rng.choice([-1,0,0,0,1]) if rough else 0
        for stroke in GLYPHS.get(ch,[]):
            pts=[(int(x+a*size),int(y+b*size+dy)) for a,b in stroke]
            line(im,pts,color,width)
        x+=(5+spacing)*size

def marks(im,box,count,color,width=1,seed=0):
    rng=random.Random(seed); x1,y1,x2,y2=box
    for i in range(count):
        x=rng.randint(x1,x2); y=rng.randint(y1,y2)
        line(im,[(x,y),(x+rng.randint(1,7),y+rng.choice([-1,0,0,1]))],color,width)

def save(im,name):
    im.save(ART/f'{name}.png')
    im.save(LAYERS/f'{name}.png')
    manifest[name]={'width':im.width,'height':im.height,'runtime':f'assets/art/{name}.png'}

def composite(base,layer,name=None):
    if name: layer.save(LAYERS/f'{name}.png')
    return Image.alpha_composite(base,layer)

def figure(im,x,y,s=1,color=DEEP,eyes=False,wave_hand=False):
    # Deliberately bent shoulders, too-long hands, awkward cap-shaped skull.
    def p(points): return [(int(x+a*s),int(y+b*s)) for a,b in points]
    poly(im,p([(-8,19),(-14,22),(-20,63),(-14,67),(-8,43),(-8,78),(-11,111),(-2,111),(1,80),(5,112),(13,112),(9,71),(13,35),(18,57),(24,55),(16,21),(7,17)]),color,None)
    ellipse(im,(x-10*s,y-3*s,x+10*s,y+22*s),color,None)
    if eyes:
        rect(im,(int(x-6*s),int(y+8*s),int(x-3*s),int(y+10*s)),CREAM)
        rect(im,(int(x+3*s),int(y+8*s),int(x+6*s),int(y+10*s)),CREAM)
    if wave_hand:
        line(im,p([(10,27),(21,35),(29,9)]),color,max(2,int(6*s)))
        for k in range(4): line(im,p([(29,9),(25+k*3,-3-k%2*3)]),color,max(1,int(2*s)))

def exterior(day=False):
    im=canvas(color='#887f77' if day else DEEP)
    sky=canvas(); d=draw(sky)
    # Each cloud is a block of hand-composed contour, no smooth gradient.
    for pts,col in [([(0,16),(105,29),(164,9),(267,26),(340,5),(463,25),(564,13),(640,28),(640,0),(0,0)],'#c4ad86' if day else '#111a2c'),
                    ([(0,69),(120,55),(183,78),(294,50),(426,72),(515,56),(640,66),(640,34),(0,33)],'#ac987f' if day else '#172033')]: poly(sky,pts,col,None)
    # Bushes and empty road disappearing into the woods.
    for x in range(-8,664,15):
        h=25+(x*13%36)
        poly(sky,[(x-11,182),(x,99-h),(x+6,147),(x+17,181)],'#44464a' if day else '#0c1522',None)
    for x in [22,51,77,547,576,613]:
        line(sky,[(x,49),(x+3,208)],'#313540' if day else '#050b15',4)
        line(sky,[(x,86),(x-19,62),(x-23,40)],DEEP,2)
        line(sky,[(x,105),(x+19,77),(x+22,49)],DEEP,2)
    im=composite(im,sky,'exterior_day_sky' if day else 'exterior_night_sky')
    store=canvas()
    # Broken roofline and tall cheap sign.
    poly(store,[(79,134),(505,139),(535,235),(66,234)],'#514f50',DEEP,3)
    poly(store,[(82,119),(472,112),(518,128),(78,140)],'#4d5761',DEEP,3)
    poly(store,[(80,135),(494,138),(491,235),(77,233)],'#9c9983' if day else '#656d65',DEEP,3)
    rect(store,(86,154,479,226),'#a1a38c' if day else '#4f6460',DEEP,2)
    # Narrow green strip under the eaves, grimy bricks and uneven parking canopy.
    rect(store,(75,133,501,144),YELLOW if day else '#9c9859',DEEP,3)
    rect(store,(84,145,493,150),'#314c47')
    for y in [151,176,201,226]:
        line(store,[(77,y),(493,y+1)],'#515857',1)
        for x in range(77+(12 if y%2 else 0),490,28): line(store,[(x,y),(x,y+22)],'#515857',1)
    # Frontage windows: intentionally not geometrically perfect.
    for x,w in [(92,100),(202,88),(346,126)]:
        poly(store,[(x,157),(x+w,157),(x+w-2,222),(x,224)],'#363f43' if day else '#1b2d35',DEEP,3)
        rect(store,(x+4,161,x+w-5,166),'#8eac8b' if day else '#829274')
        for sy in [191,207]:
            rect(store,(x+5,sy,x+w-4,sy+3),'#798476' if day else '#485755')
            for px in range(x+9,x+w-9,10):
                rect(store,(px,sy-10,px+6,sy-1),['#8c9275','#727f74','#767159'][px%3])
        line(store,[(x+14,168),(x+33,182)],'#596963',2)
        line(store,[(x+28,168),(x+43,179)],'#435d5e',1)
    poly(store,[(299,155),(336,156),(335,229),(298,229)],'#303b3d',DEEP,3)
    rect(store,(304,161,330,206),'#778b7c' if day else '#29383a',DEEP)
    line(store,[(327,192),(327,202)],YELLOW,2)
    letter(store,'PULL',(307,211),.64,CREAM,1)
    # Front hanging signage becomes a shelter for the titular dead-end stop.
    poly(store,[(172,87),(405,90),(408,132),(168,129)],'#555954',DEEP,4)
    poly(store,[(179,94),(398,96),(399,125),(177,121)],'#a5a180' if day else '#8e916e',DEEP,2)
    letter(store,'THE LAST STOP',(191,100),2.3,INK,2,spacing=.7)
    line(store,[(192,96),(259,95)],'#d1cc96',1)
    line(store,[(379,127),(388,125),(389,112)],RED,2)
    line(store,[(199,88),(199,78),(376,81),(377,89)],INK,2)
    # OPEN sign and poster.
    rect(store,(223,172,272,188),INK,CREAM,1)
    letter(store,'OPEN',(228,176),1.4,RED,1,spacing=.5)
    rect(store,(101,176,122,201),YELLOW,INK,1)
    letter(store,'24',(105,180),1.4,INK,1)
    line(store,[(105,195),(118,195)],RED,2)
    # Two bins, attendant silhouette, slouching under the light.
    poly(store,[(440,219),(458,218),(460,242),(439,242)],'#3b4649',DEEP,2)
    rect(store,(437,217,462,222),'#465052',DEEP,2)
    if not day: figure(store,318,180,.40,DEEP,False)
    else:
        for x,y,s in [(112,179,.36),(148,176,.4),(244,177,.39),(365,177,.39),(390,176,.40),(444,174,.42)]:
            figure(store,x,y,s,'#242732',True,True)
    # Sign pole plus out-of-date gas price.
    poly(store,[(556,76),(581,74),(582,88),(558,89)],'#7e826f',DEEP,2)
    rect(store,(566,87,572,246),'#333d49')
    poly(store,[(549,36),(590,38),(589,80),(550,81)],'#a19c78',DEEP,3)
    letter(store,'LAST',(554,44),1.25,INK,1)
    letter(store,'STOP',(554,59),1.25,INK,1)
    rect(store,(549,91,591,111),INK,BLUE,2)
    letter(store,'6.66',(554,98),1.2,RED,1)
    im=composite(im,store,'exterior_day_store' if day else 'exterior_night_store')
    ground=canvas()
    poly(ground,[(0,240),(74,231),(489,232),(640,246),(640,360),(0,360)],'#6f716b' if day else '#151e2b',None)
    poly(ground,[(78,232),(492,232),(521,253),(63,255)],'#999c89' if day else '#4a5657',DEEP,2)
    line(ground,[(77,241),(499,242)],'#798478' if day else '#687464',2)
    for x in [105,190,378,478]:
        line(ground,[(x,266),(x-23 if x<320 else x+23,317)],'#b9ac83' if day else '#5a5f4c',3)
    # Water reflections drawn as broken strokes, never glossy gradients.
    for x,y,w,col in [(180,265,60,'#5f685c'),(226,283,47,'#424f4e'),(289,253,53,'#68775e'),(306,276,43,'#62715f'),(260,310,50,'#303d43'),(555,266,32,'#695b4c')]:
        for j in range(6): line(ground,[(x-j%3*5,y+j*3),(x+w-(j*7%23),y+j*3)],col,1 if j%2 else 2)
    line(ground,[(23,338),(64,329),(99,338),(123,334)],'#3b454c',2)
    line(ground,[(451,341),(473,330),(505,333),(519,322)],'#2b3643',2)
    marks(ground,(0,251,635,357),180,'#858578' if day else '#25303b',1,7)
    im=composite(im,ground,'exterior_day_ground' if day else 'exterior_night_ground')
    rain=canvas()
    if not day:
        rng=random.Random(14)
        for k in range(95):
            x=rng.randrange(640); y=rng.randrange(360)
            line(rain,[(x,y),(x-3,y+9)],'#4c6173' if k%5==0 else '#263848',1)
    else:
        poly(rain,[(0,196),(77,242),(285,360),(0,360)],(213,194,139,33),None)
        line(rain,[(16,150),(24,149)],CREAM,2)
    im=composite(im,rain,'exterior_day_atmosphere' if day else 'exterior_night_rain')
    return im

def interior():
    im=canvas(color='#222d38')
    walls=canvas()
    poly(walls,[(0,0),(640,0),(493,75),(143,74)],'#253039',None)
    poly(walls,[(0,0),(147,73),(149,246),(0,339)],'#39474c',DEEP,2)
    poly(walls,[(640,0),(493,75),(492,243),(640,339)],'#2e3e44',DEEP,2)
    poly(walls,[(145,73),(494,74),(493,245),(148,245)],'#394946',DEEP,3)
    rect(walls,(146,77,494,117),'#56645b')
    rect(walls,(146,115,494,121),'#8b8970')
    rect(walls,(147,123,494,130),'#4e564b')
    # Suspended fluorescents; ceiling grids draw the eye into the back room.
    for y,x,w in [(22,178,285),(50,223,194),(68,265,112)]:
        poly(walls,[(x,y),(x+w,y),(x+w-15,y+6),(x+12,y+6)],'#929c78',DEEP,2)
        line(walls,[(x+12,y+3),(x+w-18,y+3)],'#c4cba0',2)
    for x in [45,174,323,459,602]: line(walls,[(x,0),(320+(x-320)*.38,75)],INK,1)
    for y in [13,37,63]: line(walls,[(y*1.96,y),(640-y*1.96,y)],INK,1)
    # Tile floor laid by someone who could not be bothered with a ruler.
    poly(walls,[(148,240),(491,240),(640,335),(640,360),(0,360),(0,339)],'#4a5356',INK,2)
    for y in [254,273,300,338]: line(walls,[(0,y),(640,y+1)],'#28343b',2)
    for x in range(-180,900,95): line(walls,[(320+(x-320)*.27,240),(x,360)],'#29343b',2)
    for pts in [[(47,305),(126,305),(79,340),(0,340)],[(269,273),(306,273),(303,300),(253,300)],[(440,299),(499,299),(565,337),(483,337)],[(337,255),(364,255),(377,273),(344,272)]]:
        poly(walls,pts,'#596057',None)
    marks(walls,(152,81,483,230),85,'#45534d',1,17)
    marks(walls,(10,254,628,351),125,'#60655d',1,1)
    im=composite(im,walls,'interior_architecture')
    furniture=canvas()
    # The shut stockroom door is an environmental anchor.
    poly(furniture,[(270,131),(329,130),(330,241),(270,241)],'#202c34',DEEP,3)
    rect(furniture,(275,136,324,236),'#344147',DEEP,2)
    rect(furniture,(283,149,317,169),'#a7a88b',INK,1)
    letter(furniture,'STAFF',(287,152),.85,INK,1)
    letter(furniture,'ONLY',(288,162),.75,INK,1)
    line(furniture,[(315,189),(315,197)],YELLOW,2)
    line(furniture,[(278,239),(324,239)],PURPLE,1)
    # Wall clock always short of quitting time.
    ellipse(furniture,(343,83,371,111),'#b5b495',DEEP,3)
    line(furniture,[(356,97),(356,87)],INK,2)
    line(furniture,[(356,97),(365,102)],INK,2)
    # Left shelves all manually stocked.
    poly(furniture,[(8,127),(223,157),(225,279),(9,326)],'#4f5b59',DEEP,3)
    for y in [149,191,232,278]:
        dy=(y-149)*-.17
        poly(furniture,[(11,y),(221,159+(y-149)*.65),(221,167+(y-149)*.65),(10,y+10)],'#9b9576',DEEP,2)
        if y<278:
            for j,x in enumerate(range(19,211,23)):
                py=y+(x-11)/210*(159-y)-22
                c=[BLUE,'#997d6a',YELLOW,'#6c8271',RED][j%5]
                poly(furniture,[(x,py),(x+14,py+2),(x+14,py+23),(x,py+21)],c,DEEP,1)
                line(furniture,[(x+3,py+9),(x+12,py+10)],CREAM,2)
    # Freezers at the right are colder than the rest of the room.
    poly(furniture,[(443,148),(635,110),(635,306),(443,268)],'#616e6e',DEEP,3)
    for j in range(3):
        x=449+j*60
        yt=151-j*12; yb=265+j*12
        poly(furniture,[(x,yt),(x+51,yt-10),(x+51,yb+10),(x,yb)],'#263942',DEEP,3)
        for y in [188,221,251]:
            line(furniture,[(x+4,y),(x+47,y-2)],'#697973',2)
            for px in range(x+8,x+45,12): rect(furniture,(px,y-14,px+7,y-2),'#809184',DEEP,1)
        line(furniture,[(x+44,193),(x+44,221)],'#aab399',2)
        line(furniture,[(x+10,yt+15),(x+31,yt+24)],'#4b666c',2)
    # Counter foreground and forgotten till, deliberately framing clear center.
    poly(furniture,[(0,311),(121,279),(235,300),(209,360),(0,360)],'#645c4b',DEEP,3)
    poly(furniture,[(0,305),(119,273),(244,294),(237,307),(0,327)],'#9c977c',DEEP,3)
    poly(furniture,[(57,280),(110,266),(148,274),(97,290)],INK,DEEP,2)
    poly(furniture,[(65,279),(60,245),(104,239),(112,268)],'#445451',DEEP,3)
    poly(furniture,[(68,272),(65,249),(100,244),(105,265)],'#7d927b',DEEP,2)
    line(furniture,[(73,257),(95,253)],INK,2)
    line(furniture,[(74,265),(90,261)],INK,2)
    # Employee board and red telephone.
    rect(furniture,(160,89,202,129),'#786b4d',INK,2)
    rect(furniture,(166,96,178,111),'#d0c5a1',INK,1)
    rect(furniture,(185,101,196,120),'#c0b594',INK,1)
    poly(furniture,[(383,188),(416,188),(415,209),(380,211)],'#754141',DEEP,2)
    line(furniture,[(383,188),(378,181),(383,177),(411,177),(418,183),(414,189)],RED,5)
    line(furniture,[(414,190),(420,196),(417,201),(423,207),(419,214),(425,218)],DEEP,2)
    im=composite(im,furniture,'interior_furniture')
    return im

def person(kind='customer'):
    im=canvas(160,240)
    # Asymmetry is intentional: mundane weariness becomes an impossible face.
    cloth=BLUE if kind=='player' else '#697264'
    if kind=='monster':
        figure(im,79,25,1.75,DEEP,True,True)
        line(im,[(56,45),(61,63),(102,62),(111,42)],'#2e293f',3)
        for x in [60,65,72,79,87,95]: line(im,[(x,66),(x+2,83)],PURPLE,2)
        return im
    poly(im,[(43,105),(16,130),(12,236),(143,236),(142,137),(114,107)],cloth,DEEP,4)
    poly(im,[(64,99),(60,123),(84,134),(102,116),(97,96)],'#948b76',DEEP,3)
    poly(im,[(42,46),(58,27),(101,31),(117,56),(109,96),(92,114),(59,101),(44,74)],'#b5ab8e',DEEP,3)
    poly(im,[(42,56),(38,32),(51,16),(88,14),(115,26),(119,53),(107,48),(103,35),(68,40),(53,34),(53,57)],'#343638',DEEP,3)
    ellipse(im,(42,59,53,82),'#ab9d80',DEEP,2)
    line(im,[(63,63),(74,60)],INK,3); line(im,[(91,60),(102,64)],INK,3)
    rect(im,(65,68,70,71),INK); rect(im,(93,69,97,72),INK)
    line(im,[(82,66),(79,83),(86,84)],'#716e61',2)
    line(im,[(66,93),(76,90),(91,92)],INK,2)
    line(im,[(60,76),(70,77)],'#8d8878',2)
    line(im,[(92,78),(103,76)],'#8d8878',2)
    poly(im,[(42,115),(57,113),(77,144),(52,168)],'#87917b',DEEP,3)
    poly(im,[(109,112),(121,126),(101,167),(80,143)],'#87917b',DEEP,3)
    line(im,[(81,145),(79,236)],DEEP,3)
    for y in [169,189,211]: ellipse(im,(82,y,86,y+4),CREAM,INK,1)
    rect(im,(22,165,64,183),YELLOW,DEEP,2)
    letter(im,'NIGHT',(27,170),1.05,INK,1)
    line(im,[(27,178),(53,178)],INK,1)
    line(im,[(112,162),(115,213)],'#465350',3)
    line(im,[(30,185),(26,232)],'#465350',3)
    if kind=='player':
        poly(im,[(41,34),(42,19),(64,9),(108,17),(121,39)],'#546a75',DEEP,3)
        poly(im,[(35,34),(99,30),(125,38),(119,44),(40,42)],BLUE,DEEP,3)
        letter(im,'LS',(69,19),1.4,CREAM,1)
    return im

def product(kind):
    im=canvas(96,128)
    if kind=='can':
        rect(im,(21,29,74,111),'#7c8a73',DEEP,3)
        ellipse(im,(21,19,74,38),'#adb096',DEEP,3)
        ellipse(im,(22,101,74,118),'#7d8975',DEEP,3)
        rect(im,(23,42,72,94),RED,DEEP,2)
        ellipse(im,(33,50,62,78),YELLOW,DEEP,2)
        line(im,[(47,47),(50,57)],GREEN,3)
        letter(im,'SOUP',(29,83),1.5,CREAM,1)
        line(im,[(34,26),(59,26)],INK,2)
    elif kind=='cereal':
        poly(im,[(16,20),(72,16),(82,26),(81,113),(23,119),(15,108)],'#c3ac65',DEEP,3)
        poly(im,[(72,16),(82,26),(81,113),(72,106)],'#8d8158',DEEP,2)
        letter(im,'NIGHT',(24,31),1.3,INK,1)
        letter(im,'BITES',(24,46),1.3,RED,1)
        ellipse(im,(26,71,64,101),CREAM,DEEP,2)
        for x,y in [(34,75),(46,79),(53,72),(38,89),(52,91)]: ellipse(im,(x,y,x+6,y+5),YELLOW,INK,1)
        line(im,[(25,107),(65,106)],RED,3)
    else:
        poly(im,[(21,36),(31,13),(64,13),(75,33),(75,114),(21,114)],CREAM,DEEP,3)
        poly(im,[(31,13),(38,28),(75,33),(64,13)],'#9faaa0',DEEP,2)
        line(im,[(31,13),(63,13)],BLUE,4)
        rect(im,(23,39,72,99),BLUE if kind=='milk' else '#746984',DEEP,2)
        letter(im,'MILK',(29,47),1.6,CREAM,1)
        if kind=='milk':
            poly(im,[(37,73),(44,65),(54,67),(62,76),(58,91),(40,92),(34,83)],CREAM,INK,2)
            rect(im,(41,73,44,77),INK); rect(im,(52,73,55,77),INK)
            line(im,[(42,85),(54,86)],INK,2)
        else:
            ellipse(im,(30,65,65,89),CREAM,DEEP,2)
            ellipse(im,(43,66,56,88),PURPLE,DEEP,2)
            ellipse(im,(48,70,53,85),INK,None)
            line(im,[(21,101),(11,111),(9,104)],PURPLE,3)
            line(im,[(74,105),(84,100),(87,111)],PURPLE,3)
            line(im,[(35,117),(30,124),(25,119)],PURPLE,3)
            line(im,[(59,117),(65,124),(70,118)],PURPLE,3)
        letter(im,'1L',(32,104),.8,INK,1)
    return im

def props():
    im=canvas(160,200)
    poly(im,[(15,12),(143,8),(148,186),(11,192)],'#867558',DEEP,4)
    poly(im,[(25,22),(133,21),(134,175),(24,178)],CREAM,DEEP,2)
    poly(im,[(57,8),(66,3),(100,3),(109,9),(109,28),(56,29)],BLUE,DEEP,3)
    rect(im,(69,8,97,17),'#9aab9b',DEEP,2)
    letter(im,'SHIFT',(41,42),2.5,INK,2)
    for y in [72,94,116,138,160]:
        rect(im,(32,y,40,y+8),None,INK,1)
        line(im,[(48,y+3),(121-(y%3)*7,y+2)],'#777766',2)
    save(im,'clipboard')
    im=canvas(160,160)
    poly(im,[(25,60),(126,54),(143,132),(16,139)],'#793b3c',DEEP,4)
    poly(im,[(27,55),(34,39),(118,37),(133,55),(126,76),(108,72),(106,57),(49,60),(47,78),(24,77)],RED,DEEP,4)
    ellipse(im,(54,76,103,122),'#b39c79',DEEP,3)
    ellipse(im,(65,87,92,111),'#6c5147',DEEP,2)
    for i in range(10):
        a=i*math.pi*2/10
        x=78+20*math.cos(a); y=99+19*math.sin(a)
        ellipse(im,(x-3,y-3,x+3,y+3),INK,None)
    pts=[(127,77)]+[(144+(i%2)*6,81+i*5) for i in range(13)]+[(138,149),(119,149)]
    line(im,pts,DEEP,3)
    line(im,[(28,121),(42,120)],'#bd7160',2)
    save(im,'phone')
    im=canvas(160,240)
    poly(im,[(16,5),(148,7),(144,233),(13,235)],'#556262',DEEP,4)
    poly(im,[(26,15),(136,17),(134,225),(24,225)],'#343f46',DEEP,3)
    rect(im,(41,43,122,86),CREAM,DEEP,3)
    letter(im,'STOCK',(48,50),2.2,INK,2)
    letter(im,'ROOM',(53,70),1.8,INK,1)
    line(im,[(116,128),(116,148)],YELLOW,4)
    ellipse(im,(109,117,121,129),'#8a957f',DEEP,2)
    for pts in [[(43,110),(38,163)],[(50,112),(47,167)],[(58,116),(54,169)]]: line(im,pts,'#727066',2)
    line(im,[(27,222),(132,222)],PURPLE,2)
    save(im,'door')
    im=canvas(160,100)
    line(im,[(116,61),(139,65),(153,52),(150,40),(139,35)],'#937c80',4)
    poly(im,[(21,59),(47,27),(85,25),(116,45),(117,68),(49,81),(14,67)],'#8d9184',DEEP,3)
    ellipse(im,(38,24,61,49),'#a19c87',DEEP,3)
    ellipse(im,(44,28,55,42),'#9c7471',None)
    poly(im,[(38,45),(18,50),(6,63),(36,73),(56,68)],'#939a88',DEEP,2)
    ellipse(im,(23,53,28,57),CREAM,DEEP,1)
    rect(im,(8,61,13,66),RED)
    line(im,[(49,75),(43,87),(31,87)],INK,3)
    line(im,[(97,70),(105,83),(94,87)],INK,3)
    for y in [58,63,69]: line(im,[(18,y),(0,y-4)],'#b0ad95',1)
    save(im,'rat')
    im=canvas(160,160)
    line(im,[(102,5),(60,127)],DEEP,10); line(im,[(101,7),(59,128)],'#ab9671',6)
    poly(im,[(39,116),(78,126),(73,137),(33,128)],BLUE,DEEP,3)
    for i in range(11): line(im,[(36+i*4,129),(25+i*5,145+(i%3)*3)],CREAM,3)
    line(im,[(51,112),(65,116)],INK,3)
    save(im,'mop')
    im=canvas(160,180)
    poly(im,[(12,12),(149,7),(148,169),(13,174)],'#687574',DEEP,4)
    poly(im,[(23,27),(137,25),(137,146),(24,150)],'#28363c',DEEP,3)
    for i in range(6):
        x=34+(i%3)*35; y=45+(i//3)*57
        rect(im,(x,y,x+25,y+32),'#536563',DEEP,2)
        rect(im,(x+6,y+5,x+19,y+19),RED if i==4 else CREAM,DEEP,2)
        letter(im,str(i+1),(x+9,y+36),1,GREEN,1)
    poly(im,[(52,160),(61,148),(69,160)],YELLOW,DEEP,1)
    letter(im,'!',(58,151),.6,INK,1)
    for x,y in [(17,17),(143,14),(18,166),(143,165)]: ellipse(im,(x-2,y-2,x+2,y+2),INK,None)
    save(im,'breaker')
    im=canvas(240,200)
    poly(im,[(12,15),(226,18),(233,173),(6,176)],'#5a6966',DEEP,5)
    poly(im,[(26,29),(202,32),(203,144),(24,145)],DEEP,INK,4)
    rect(im,(31,37,195,138),'#334940')
    for y in range(39,138,5): line(im,[(31,y),(196,y)],'#243b35',1)
    poly(im,[(31,98),(85,63),(146,66),(195,97),(195,137),(31,137)],'#41594b',None)
    line(im,[(80,75),(80,123),(157,124),(158,77)],'#91a387',2)
    figure(im,129,73,.53,DEEP,True)
    letter(im,'CAM 4',(37,43),1.3,GREEN,1)
    letter(im,'3:33',(140,125),1.3,GREEN,1)
    for y in [45,69,96]: ellipse(im,(212,y,224,y+11),INK,GREEN,1)
    rect(im,(33,154,171,161),INK)
    line(im,[(87,177),(82,190),(156,190),(150,175)],DEEP,7)
    save(im,'cctv')
    im=canvas(240,240)
    poly(im,[(14,20),(219,13),(229,226),(8,232)],'#586560',DEEP,4)
    for y in [61,119,177,225]:
        rect(im,(18,y,222,y+9),'#ab9c73',DEEP,3)
        if y<220:
            for j in range(6):
                p=product(['milk','can','cereal'][j%3]).resize((28,41),Image.Resampling.NEAREST)
                im.alpha_composite(p,(23+j*32,y-39))
    save(im,'shelf')
    im=canvas(240,240)
    poly(im,[(14,12),(224,14),(226,232),(13,230)],'#8c9a8d',DEEP,4)
    for x in [23,124]:
        rect(im,(x,23,x+89,219),'#29404a',DEEP,3)
        for y in [76,125,177,211]:
            line(im,[(x+6,y),(x+82,y)],'#829b87',3)
            if y<210:
                for j in range(4):
                    rect(im,(x+8+j*18,y-32,x+21+j*18,y-3),'#839e93',DEEP,1)
                    rect(im,(x+10+j*18,y-22,x+20+j*18,y-12),BLUE)
        line(im,[(x+72,99),(x+72,151)],CREAM,3)
        line(im,[(x+11,38),(x+52,68)],'#567681',3)
        line(im,[(x+18,33),(x+61,65)],'#567681',1)
    save(im,'freezer')
    im=canvas(320,180)
    poly(im,[(10,83),(119,53),(308,75),(308,166),(18,166)],'#6f6653',DEEP,4)
    poly(im,[(10,81),(119,47),(309,69),(310,91),(16,119)],CREAM,DEEP,4)
    poly(im,[(143,70),(137,15),(211,17),(216,66)],BLUE,DEEP,4)
    poly(im,[(151,60),(147,25),(201,26),(205,57)],'#8ba183',DEEP,3)
    letter(im,'6.66',(156,36),1.5,INK,1)
    poly(im,[(151,67),(216,62),(243,77),(174,88)],'#53665f',DEEP,3)
    for y in range(70,80,4): line(im,[(171,y),(223,y-4)],CREAM,1)
    poly(im,[(43,77),(93,63),(117,77),(66,91)],INK,DEEP,3)
    line(im,[(54,77),(98,76)],RED,3)
    save(im,'checkout')
    im=canvas(200,110)
    poly(im,[(15,43),(144,21),(188,58),(63,96)],'#7c8b7e',DEEP,4)
    poly(im,[(35,48),(139,33),(166,56),(65,79)],INK,DEEP,3)
    line(im,[(47,52),(149,53)],RED,4)
    line(im,[(52,62),(151,62)],'#6e393d',1)
    ellipse(im,(159,69,170,79),GREEN,DEEP,2)
    save(im,'scanner')
    # HUD assets maintain readable silhouette and rough edging.
    im=canvas(64,64)
    poly(im,[(9,7),(51,9),(53,35),(33,58),(12,39)],GREEN,DEEP,3)
    poly(im,[(19,28),(28,37),(44,19),(47,23),(28,45),(16,33)],INK,None)
    line(im,[(14,12),(27,13)],CREAM,2)
    save(im,'safety')
    im=canvas(32,32)
    poly(im,[(3,2),(4,25),(10,20),(16,30),(21,27),(15,17),(25,15)],CREAM,DEEP,2)
    save(im,'cursor')
    im=canvas(220,70)
    poly(im,[(6,8),(208,4),(216,59),(11,65)],'#8d997a',DEEP,3)
    line(im,[(12,12),(195,10)],'#c3c5a1',2)
    line(im,[(16,60),(205,55)],'#5a685c',2)
    save(im,'button')
    im=canvas(360,260)
    poly(im,[(18,13),(334,10),(345,230),(319,246),(20,246),(26,167),(12,97)],CREAM,DEEP,3)
    poly(im,[(320,246),(319,226),(345,229)],'#9d997e',DEEP,1)
    for y in range(45,229,22): line(im,[(34,y),(320,y+1)],'#aeb09a',1)
    line(im,[(59,20),(57,237)],'#b38377',1)
    marks(im,(24,14,327,238),80,'#c4bfa4',1,23)
    for x in [39,171,306]:
        poly(im,[(x,2),(x+29,0),(x+33,23),(x+1,25)],(148,151,115,180),None)
    save(im,'note')

def death_board():
    im=canvas(color='#17212d')
    poly(im,[(48,21),(592,25),(603,335),(39,335)],'#615744',DEEP,6)
    poly(im,[(60,33),(582,35),(589,321),(54,322)],'#7c7453',DEEP,3)
    marks(im,(61,38,580,315),1600,'#6d674c',1,16)
    title=canvas(440,43,CREAM)
    letter(title,'OUR NIGHT FAMILY',(24,10),3.5,INK,3)
    im.alpha_composite(title,(99,45))
    for i,(x,y) in enumerate([(84,105),(224,108),(382,107),(104,218),(269,218),(428,215)]):
        poly(im,[(x-5,y-3),(x+83,y),(x+86,y+85),(x-4,y+81)],CREAM,DEEP,2)
        rect(im,(x+2,y+4,x+76,y+64),'#26343c')
        if i==4:
            portrait=person('player').resize((42,63),Image.Resampling.NEAREST)
            im.alpha_composite(portrait,(x+18,y+3))
            # The same employee portrait used in the shift, now filed away.
            line(im,[(x+7,y+54),(x+65,y+55)],RED,2)
        else:
            figure(im,x+39,y+13,.43,DEEP,True,i==5)
            if i==2:
                for dx in [-5,1,5]: line(im,[(x+40+dx,y+19),(x+40+dx,y+39)],PURPLE,1)
        letter(im,['ELLIS','MORGAN','JUNE','SAM','YOU','MANAGER'][i],(x+4,y+71),1.2,INK,1)
        ellipse(im,(x+34,y-6,x+42,y+1),RED,DEEP,1)
    line(im,[(342,110),(335,142),(350,169),(336,193)],RED,2)
    return im

def logo():
    im=canvas(620,170)
    poly(im,[(15,16),(593,9),(605,99),(10,107)],CREAM,DEEP,5)
    marks(im,(18,17,590,98),190,'#b5b093',1,2)
    letter(im,'CLOCK OUT',(31,24),10.4,INK,7,spacing=.2)
    poly(im,[(145,91),(456,87),(468,152),(136,159)],RED,DEEP,4)
    letter(im,'ALIVE',(170,97),7.8,CREAM,6,spacing=1.1)
    # Three intentionally rough employee-punch perforations.
    for x in [36,68,101]: ellipse(im,(x,124,x+12,137),CREAM,DEEP,2)
    line(im,[(477,124),(580,122)],BLUE,3)
    line(im,[(480,137),(553,135)],BLUE,3)
    return im

def make_art():
    save(exterior(),'exterior')
    save(exterior(True),'ending_winner')
    save(interior(),'interior')
    save(death_board(),'ending_death')
    save(logo(),'logo')
    for name in ['player','customer','monster']: save(person(name),name)
    for name in ['milk','cereal','can','living']: save(product(name),'product_'+name)
    props()
    # Exact semantic aliases are useful to UI code and asset inventory.
    for original,alias in [('ending_death','noticeboard'),('monster','anomaly'),('exterior','loading')]:
        save(Image.open(ART/f'{original}.png'),alias)
    (ROOT/'source_art'/'art_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')

# Original synthesis: oscillators, filtered pseudorandom noise, envelopes.
# Save uncompressed mono 22.05kHz PCM, sufficiently light for web and Godot.
SR=22050
nrng=np.random.default_rng(333)
def noise(n): return nrng.normal(0,1,n)
def lowpass(sig,k=12): return np.convolve(sig,np.ones(k)/k,'same')
def env(n,attack=.01,release=.1):
    e=np.ones(n); a=min(n,int(SR*attack)); r=min(n-a,int(SR*release))
    if a:e[:a]=np.linspace(0,1,a)
    if r:e[-r:]=np.linspace(1,0,r)
    return e
def sine(t,f): return np.sin(2*np.pi*f*t)
def tone(freq,duration,volume=.2):
    t=np.arange(int(SR*duration))/SR
    return volume*sine(t,freq)*env(len(t),.008,.07)
def emit(name,sig,loop=False):
    sig=np.clip(sig,-.88,.88)
    if loop:
        # Match both endpoints with a short seam ramp, keeping sustained beds.
        n=min(int(SR*.1),len(sig)//8)
        sig[:n]*=np.linspace(0,1,n); sig[-n:]*=np.linspace(1,0,n)
    with wave.open(str(AUDIO/f'{name}.wav'),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR)
        w.writeframes((sig*32767).astype('<i2').tobytes())
    return round(len(sig)/SR,3)
def add_at(out,pulse,start):
    offset=int(start*SR); end=min(len(out),offset+len(pulse))
    if end>offset: out[offset:end]+=pulse[:end-offset]

def make_audio():
    durations={}
    t=np.arange(SR*12)/SR; n=noise(len(t))
    rain=.065*(n-lowpass(n,8))+.05*lowpass(n,38)
    for k in range(55):
        dur=.015+(k%5)*.01; tt=np.arange(int(SR*dur))/SR
        drop=.07*noise(len(tt))*np.exp(-tt*100)
        add_at(rain,drop,float(nrng.uniform(0,11.9)))
    durations['rain']=emit('rain',rain,True)
    t=np.arange(SR*8)/SR
    hum=.09*sine(t,58)+.02*sine(t,116)+.01*lowpass(noise(len(t)),50)
    hum*=.88+.12*sine(t,.5)
    durations['hum']=emit('hum',hum,True)
    buzz=.025*sine(t,120)+.013*sine(t,360)+.009*noise(len(t))
    buzz*=.80+.12*sine(t,7)+.08*sine(t,3)
    durations['buzz']=emit('buzz',buzz,True)
    # Sparse, detuned electric-piano fragment. Original eight-bar progression.
    t=np.arange(SR*24)/SR; music=np.zeros(len(t))
    chords=[(146.83,174.61,220.0),(130.81,164.81,196),(123.47,146.83,196),(130.81,164.81,207.65)]
    for k,chord in enumerate(chords):
        for j,f in enumerate(chord):
            tt=np.arange(int(SR*5.8))/SR
            attack=1-np.exp(-tt*60)
            decay=np.exp(-tt*.75)
            note=.065*(sine(tt,f)+.20*sine(tt,2*f)+.045*sine(tt,f*1.002))*attack*decay
            add_at(music,note,k*6+j*.075)
        tt=np.arange(int(SR*4))/SR
        add_at(music,.08*sine(tt,chord[0]/2)*(1-np.exp(-tt*8))*np.exp(-tt),k*6)
    music+=.002*lowpass(noise(len(t)),3)
    durations['music']=emit('music',music,True)
    # Music can lose its harmonic layer, leaving only an unstable sub-bass bed.
    t=np.arange(SR*12)/SR
    tension=.047*sine(t,43.5)+.033*sine(t,44)+.014*sine(t,87)
    tension*=.72+.28*sine(t,.25)
    durations['tension']=emit('tension',tension,True)
    durations['scanner']=emit('scanner',tone(1046.5,.11,.15))
    t=np.arange(int(SR*.23))/SR
    durations['footstep']=emit('footstep',(.10*lowpass(noise(len(t)),20)+.10*sine(t,90))*np.exp(-t*20)*env(len(t),.003,.04))
    t=np.arange(int(SR*.32))/SR
    click=.14*noise(len(t))*np.exp(-t*80)+.12*sine(t,160)*np.exp(-t*22)
    durations['breaker']=emit('breaker',click*env(len(t),.001,.04))
    t=np.arange(SR*2)/SR
    gate=((t%.13)<.075)*(t<1.35)
    ring=.08*(sine(t,440)+sine(t,480)+.3*sine(t,960))*gate
    durations['phone']=emit('phone',ring*env(len(t),.003,.04))
    t=np.arange(int(SR*1.0))/SR
    bang=.23*sine(t,57)*np.exp(-t*7)+.12*lowpass(noise(len(t)),8)*np.exp(-t*12)
    bang+=.08*sine(t,121)*np.exp(-t*15)
    durations['bang']=emit('bang',bang*env(len(t),.004,.1))
    t=np.arange(int(SR*1.65))/SR
    rough=lowpass(noise(len(t)),3)-lowpass(noise(len(t)),25)
    scrape=.07*rough*(.55+.45*sine(t,7))+.025*sine(t,370+20*sine(t,1.5))
    durations['scrape']=emit('scrape',scrape*env(len(t),.25,.45))
    t=np.arange(SR*3)/SR
    breath=.11*lowpass(noise(len(t)),5)*(np.sin(np.pi*t/3)**1.8)
    durations['breath']=emit('breath',breath*env(len(t),.5,.8))
    t=np.arange(int(SR*.65))/SR
    paper=.10*(noise(len(t))-lowpass(noise(len(t)),12))*(.6+.4*sine(t,21))
    durations['paper']=emit('paper',paper*env(len(t),.09,.28))
    t=np.arange(int(SR*2.5))/SR
    ticks=((t%.065)<.009).astype(float)
    printer=.027*sine(t,185)+ticks*.075*noise(len(t))+.017*sine(t,390)
    durations['printer']=emit('printer',printer*env(len(t),.07,.25))
    for name,freqs,spacing in [('success',[523.25,659.25,783.99],.12),('failure',[220,174.61,146.83],.17),('winner',[293.66,349.23,440,587.33,698.46],.3)]:
        out=np.zeros(int(SR*(len(freqs)*spacing+.7)))
        for k,f in enumerate(freqs): add_at(out,tone(f,.6,.10)*np.exp(-np.arange(int(SR*.6))/SR*3),k*spacing)
        durations[name]=emit(name,out)
    t=np.arange(SR*3)/SR
    death=.10*np.sin(2*np.pi*(70*t-5*t*t))+.05*np.sin(2*np.pi*104*t)+.03*lowpass(noise(len(t)),10)
    durations['death']=emit('death',death*env(len(t),.04,1.4))
    (ROOT/'source_art'/'audio_manifest.json').write_text(json.dumps({'sample_rate':SR,'channels':1,'durations_seconds':durations},indent=2)+'\n')

if __name__=='__main__':
    make_art(); make_audio()
    print(f'Created {len(manifest)} original raster assets and {len(list(AUDIO.glob("*.wav")))} original synthesized audio files.')
