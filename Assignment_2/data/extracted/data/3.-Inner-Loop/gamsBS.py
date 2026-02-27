# -*- coding: utf-8 -*-
"""
Created on Wed Jul 16 11:03:03 2014

@author: Obie
"""

from gams import *
os.chdir("C:\Users\Obie\Documents\gamsdir\projdir\BS")
ws = GamsWorkspace(debug = DebugLevel.ShowLog, working_directory = "C:\Users\Obie\Documents\gamsdir\projdir\BS")

SEH5py = ws.add_job_from_file("themodelv6SEH5.gms")
SEH5py.run(output=sys.stdout)

W5py = ws.add_job_from_file("themodelv6W5.gms")
W5py.run(output=sys.stdout)

A5dpy = ws.add_job_from_file("themodelv6A5d.gms")
A5dpy.run(output=sys.stdout)

A6py = ws.add_job_from_file("themodelv6A6.gms")
A6py.run(output=sys.stdout)

SEH7py = ws.add_job_from_file("themodelv6SEH7.gms")
SEH7py.run(output=sys.stdout)

W7py = ws.add_job_from_file("themodelv6W7.gms")
W7py.run(output=sys.stdout)

A7cpy = ws.add_job_from_file("themodelv6A7c.gms")
A7cpy.run(output=sys.stdout)

A8py = ws.add_job_from_file("themodelv6A8.gms")
A8py.run(output=sys.stdout)

A9py = ws.add_job_from_file("themodelv6A9.gms")
A9py.run(output=sys.stdout)

SEH10py = ws.add_job_from_file("themodelv6SEH10.gms")
SEH10py.run(output=sys.stdout)

W10py = ws.add_job_from_file("themodelv6W10.gms")
W10py.run(output=sys.stdout)

A10dpy = ws.add_job_from_file("themodelv6A10d.gms")
A10dpy.run(output=sys.stdout)

A11py = ws.add_job_from_file("themodelv6A11.gms")
A11py.run(output=sys.stdout)

A12py = ws.add_job_from_file("themodelv6A12.gms")
A12py.run(output=sys.stdout)

A13py = ws.add_job_from_file("themodelv6A13.gms")
A13py.run(output=sys.stdout)

A14py = ws.add_job_from_file("themodelv6A14.gms")
A14py.run(output=sys.stdout)

A15py = ws.add_job_from_file("themodelv6A15.gms")
A15py.run(output=sys.stdout)

A16py = ws.add_job_from_file("themodelv6A16.gms")
A16py.run(output=sys.stdout)

#Begin year 2

SEH17py = ws.add_job_from_file("themodelv6SEH17.gms")
SEH17py.run(output=sys.stdout)

W17py = ws.add_job_from_file("themodelv6W17.gms")
W17py.run(output=sys.stdout)

A17cpy = ws.add_job_from_file("themodelv6A17c.gms")
A17cpy.run(output=sys.stdout)

A18py = ws.add_job_from_file("themodelv6A18.gms")
A18py.run(output=sys.stdout)

SEH19py = ws.add_job_from_file("themodelv6SEH19.gms")
SEH19py.run(output=sys.stdout)

W19py = ws.add_job_from_file("themodelv6W19.gms")
W19py.run(output=sys.stdout)

A19cpy = ws.add_job_from_file("themodelv6A19c.gms")
A19cpy.run(output=sys.stdout)

A20py = ws.add_job_from_file("themodelv6A20.gms")
A20py.run(output=sys.stdout)

A21py = ws.add_job_from_file("themodelv6A21.gms")
A21py.run(output=sys.stdout)

SEH22py = ws.add_job_from_file("themodelv6SEH22.gms")
SEH22py.run(output=sys.stdout)

W22py = ws.add_job_from_file("themodelv6W22.gms")
W22py.run(output=sys.stdout)

A22dpy = ws.add_job_from_file("themodelv6A22d.gms")
A22dpy.run(output=sys.stdout)

A23py = ws.add_job_from_file("themodelv6A23.gms")
A23py.run(output=sys.stdout)

A24py = ws.add_job_from_file("themodelv6A24.gms")
A24py.run(output=sys.stdout)

A25py = ws.add_job_from_file("themodelv6A25.gms")
A25py.run(output=sys.stdout)

A26py = ws.add_job_from_file("themodelv6A26.gms")
A26py.run(output=sys.stdout)

A27py = ws.add_job_from_file("themodelv6A27.gms")
A27py.run(output=sys.stdout)

A28py = ws.add_job_from_file("themodelv6A28.gms")
A28py.run(output=sys.stdout)

#Begin year 3

SEH29py = ws.add_job_from_file("themodelv6SEH29.gms")
SEH29py.run(output=sys.stdout)

W29py = ws.add_job_from_file("themodelv6W29.gms")
W29py.run(output=sys.stdout)

A29cpy = ws.add_job_from_file("themodelv6A29c.gms")
A29cpy.run(output=sys.stdout)

A30py = ws.add_job_from_file("themodelv6A30.gms")
A30py.run(output=sys.stdout)

SEH31py = ws.add_job_from_file("themodelv6SEH31.gms")
SEH31py.run(output=sys.stdout)

W31py = ws.add_job_from_file("themodelv6W31.gms")
W31py.run(output=sys.stdout)

A31cpy = ws.add_job_from_file("themodelv6A31c.gms")
A31cpy.run(output=sys.stdout)

A32py = ws.add_job_from_file("themodelv6A32.gms")
A32py.run(output=sys.stdout)

A33py = ws.add_job_from_file("themodelv6A33.gms")
A33py.run(output=sys.stdout)

SEH34py = ws.add_job_from_file("themodelv6SEH34.gms")
SEH34py.run(output=sys.stdout)

W34py = ws.add_job_from_file("themodelv6W34.gms")
W34py.run(output=sys.stdout)

A34dpy = ws.add_job_from_file("themodelv6A34d.gms")
A34dpy.run(output=sys.stdout)

A35py = ws.add_job_from_file("themodelv6A35.gms")
A35py.run(output=sys.stdout)

A36py = ws.add_job_from_file("themodelv6A36.gms")
A36py.run(output=sys.stdout)

A37py = ws.add_job_from_file("themodelv6A37.gms")
A37py.run(output=sys.stdout)

A38py = ws.add_job_from_file("themodelv6A38.gms")
A38py.run(output=sys.stdout)

A39py = ws.add_job_from_file("themodelv6A39.gms")
A39py.run(output=sys.stdout)

A40py = ws.add_job_from_file("themodelv6A40.gms")
A40py.run(output=sys.stdout)

#Begin year 4

SEH41py = ws.add_job_from_file("themodelv6SEH41.gms")
SEH41py.run(output=sys.stdout)

W41py = ws.add_job_from_file("themodelv6W41.gms")
W41py.run(output=sys.stdout)

A41cpy = ws.add_job_from_file("themodelv6A41c.gms")
A41cpy.run(output=sys.stdout)

A42py = ws.add_job_from_file("themodelv6A42.gms")
A42py.run(output=sys.stdout)

SEH43py = ws.add_job_from_file("themodelv6SEH43.gms")
SEH43py.run(output=sys.stdout)

W43py = ws.add_job_from_file("themodelv6W43.gms")
W43py.run(output=sys.stdout)

A43cpy = ws.add_job_from_file("themodelv6A43c.gms")
A43cpy.run(output=sys.stdout)

A44py = ws.add_job_from_file("themodelv6A44.gms")
A44py.run(output=sys.stdout)

A45py = ws.add_job_from_file("themodelv6A45.gms")
A45py.run(output=sys.stdout)

SEH46py = ws.add_job_from_file("themodelv6SEH46.gms")
SEH46py.run(output=sys.stdout)

W46py = ws.add_job_from_file("themodelv6W46.gms")
W46py.run(output=sys.stdout)

A46dpy = ws.add_job_from_file("themodelv6A46d.gms")
A46dpy.run(output=sys.stdout)

A47py = ws.add_job_from_file("themodelv6A47.gms")
A47py.run(output=sys.stdout)

A48py = ws.add_job_from_file("themodelv6A48.gms")
A48py.run(output=sys.stdout)

A49py = ws.add_job_from_file("themodelv6A49.gms")
A49py.run(output=sys.stdout)

A50py = ws.add_job_from_file("themodelv6A50.gms")
A50py.run(output=sys.stdout)

A51py = ws.add_job_from_file("themodelv6A51.gms")
A51py.run(output=sys.stdout)

A52py = ws.add_job_from_file("themodelv6A52.gms")
A52py.run(output=sys.stdout)

#Begin year 5

SEH53py = ws.add_job_from_file("themodelv6SEH53.gms")
SEH53py.run(output=sys.stdout)

W53py = ws.add_job_from_file("themodelv6W53.gms")
W53py.run(output=sys.stdout)

A53cpy = ws.add_job_from_file("themodelv6A53c.gms")
A53cpy.run(output=sys.stdout)

A54py = ws.add_job_from_file("themodelv6A54.gms")
A54py.run(output=sys.stdout)

SEH55py = ws.add_job_from_file("themodelv6SEH55.gms")
SEH55py.run(output=sys.stdout)

W55py = ws.add_job_from_file("themodelv6W55.gms")
W55py.run(output=sys.stdout)

A55cpy = ws.add_job_from_file("themodelv6A55c.gms")
A55cpy.run(output=sys.stdout)

A56py = ws.add_job_from_file("themodelv6A56.gms")
A56py.run(output=sys.stdout)

A57py = ws.add_job_from_file("themodelv6A57.gms")
A57py.run(output=sys.stdout)

SEH58py = ws.add_job_from_file("themodelv6SEH58.gms")
SEH58py.run(output=sys.stdout)

W58py = ws.add_job_from_file("themodelv6W58.gms")
W58py.run(output=sys.stdout)

A58dpy = ws.add_job_from_file("themodelv6A58d.gms")
A58dpy.run(output=sys.stdout)

A59py = ws.add_job_from_file("themodelv6A59.gms")
A59py.run(output=sys.stdout)

A60py = ws.add_job_from_file("themodelv6A60.gms")
A60py.run(output=sys.stdout)

A61py = ws.add_job_from_file("themodelv6A61.gms")
A61py.run(output=sys.stdout)

A62py = ws.add_job_from_file("themodelv6A62.gms")
A62py.run(output=sys.stdout)

A63py = ws.add_job_from_file("themodelv6A63.gms")
A63py.run(output=sys.stdout)

A64py = ws.add_job_from_file("themodelv6A64.gms")
A64py.run(output=sys.stdout)

#Begin year 6

SEH65py = ws.add_job_from_file("themodelv6SEH65.gms")
SEH65py.run(output=sys.stdout)

W65py = ws.add_job_from_file("themodelv6W65.gms")
W65py.run(output=sys.stdout)

A65cpy = ws.add_job_from_file("themodelv6A65c.gms")
A65cpy.run(output=sys.stdout)

A66py = ws.add_job_from_file("themodelv6A66.gms")
A66py.run(output=sys.stdout)

SEH67py = ws.add_job_from_file("themodelv6SEH67.gms")
SEH67py.run(output=sys.stdout)

W67py = ws.add_job_from_file("themodelv6W67.gms")
W67py.run(output=sys.stdout)

A67cpy = ws.add_job_from_file("themodelv6A67c.gms")
A67cpy.run(output=sys.stdout)

A68py = ws.add_job_from_file("themodelv6A68.gms")
A68py.run(output=sys.stdout)

A69py = ws.add_job_from_file("themodelv6A69.gms")
A69py.run(output=sys.stdout)

SEH70py = ws.add_job_from_file("themodelv6SEH70.gms")
SEH70py.run(output=sys.stdout)

W70py = ws.add_job_from_file("themodelv6W70.gms")
W70py.run(output=sys.stdout)

A70dpy = ws.add_job_from_file("themodelv6A70d.gms")
A70dpy.run(output=sys.stdout)

A71py = ws.add_job_from_file("themodelv6A71.gms")
A71py.run(output=sys.stdout)

A72py = ws.add_job_from_file("themodelv6A72.gms")
A72py.run(output=sys.stdout)

A73py = ws.add_job_from_file("themodelv6A73.gms")
A73py.run(output=sys.stdout)

A74py = ws.add_job_from_file("themodelv6A74.gms")
A74py.run(output=sys.stdout)

A75py = ws.add_job_from_file("themodelv6A75.gms")
A75py.run(output=sys.stdout)

A76py = ws.add_job_from_file("themodelv6A76.gms")
A76py.run(output=sys.stdout)

#Begin year 7

SEH77py = ws.add_job_from_file("themodelv6SEH77.gms")
SEH77py.run(output=sys.stdout)

W77py = ws.add_job_from_file("themodelv6W77.gms")
W77py.run(output=sys.stdout)

A77cpy = ws.add_job_from_file("themodelv6A77c.gms")
A77cpy.run(output=sys.stdout)

A78py = ws.add_job_from_file("themodelv6A78.gms")
A78py.run(output=sys.stdout)

SEH79py = ws.add_job_from_file("themodelv6SEH79.gms")
SEH79py.run(output=sys.stdout)

W79py = ws.add_job_from_file("themodelv6W79.gms")
W79py.run(output=sys.stdout)

A79cpy = ws.add_job_from_file("themodelv6A79c.gms")
A79cpy.run(output=sys.stdout)

A80py = ws.add_job_from_file("themodelv6A80.gms")
A80py.run(output=sys.stdout)

A81py = ws.add_job_from_file("themodelv6A81.gms")
A81py.run(output=sys.stdout)

SEH82py = ws.add_job_from_file("themodelv6SEH82.gms")
SEH82py.run(output=sys.stdout)

W82py = ws.add_job_from_file("themodelv6W82.gms")
W82py.run(output=sys.stdout)

A82dpy = ws.add_job_from_file("themodelv6A82d.gms")
A82dpy.run(output=sys.stdout)

A83py = ws.add_job_from_file("themodelv6A83.gms")
A83py.run(output=sys.stdout)

A84py = ws.add_job_from_file("themodelv6A84.gms")
A84py.run(output=sys.stdout)

A85py = ws.add_job_from_file("themodelv6A85.gms")
A85py.run(output=sys.stdout)

A86py = ws.add_job_from_file("themodelv6A86.gms")
A86py.run(output=sys.stdout)

A87py = ws.add_job_from_file("themodelv6A87.gms")
A87py.run(output=sys.stdout)

A88py = ws.add_job_from_file("themodelv6A88.gms")
A88py.run(output=sys.stdout)

#Begin year 8

SEH89py = ws.add_job_from_file("themodelv6SEH89.gms")
SEH89py.run(output=sys.stdout)

W89py = ws.add_job_from_file("themodelv6W89.gms")
W89py.run(output=sys.stdout)

A89cpy = ws.add_job_from_file("themodelv6A89c.gms")
A89cpy.run(output=sys.stdout)

A90py = ws.add_job_from_file("themodelv6A90.gms")
A90py.run(output=sys.stdout)

SEH91py = ws.add_job_from_file("themodelv6SEH91.gms")
SEH91py.run(output=sys.stdout)

W91py = ws.add_job_from_file("themodelv6W91.gms")
W91py.run(output=sys.stdout)

A91cpy = ws.add_job_from_file("themodelv6A91c.gms")
A91cpy.run(output=sys.stdout)

A92py = ws.add_job_from_file("themodelv6A92.gms")
A92py.run(output=sys.stdout)

A93py = ws.add_job_from_file("themodelv6A93.gms")
A93py.run(output=sys.stdout)

SEH94py = ws.add_job_from_file("themodelv6SEH94.gms")
SEH94py.run(output=sys.stdout)

W94py = ws.add_job_from_file("themodelv6W94.gms")
W94py.run(output=sys.stdout)

A94dpy = ws.add_job_from_file("themodelv6A94d.gms")
A94dpy.run(output=sys.stdout)

A95py = ws.add_job_from_file("themodelv6A95.gms")
A95py.run(output=sys.stdout)

A96py = ws.add_job_from_file("themodelv6A96.gms")
A96py.run(output=sys.stdout)

A97py = ws.add_job_from_file("themodelv6A97.gms")
A97py.run(output=sys.stdout)

A98py = ws.add_job_from_file("themodelv6A98.gms")
A98py.run(output=sys.stdout)

A99py = ws.add_job_from_file("themodelv6A99.gms")
A99py.run(output=sys.stdout)

A100py = ws.add_job_from_file("themodelv6A100.gms")
A100py.run(output=sys.stdout)

#Begin year 9

SEH101py = ws.add_job_from_file("themodelv6SEH101.gms")
SEH101py.run(output=sys.stdout)

W101py = ws.add_job_from_file("themodelv6W101.gms")
W101py.run(output=sys.stdout)

A101cpy = ws.add_job_from_file("themodelv6A101c.gms")
A101cpy.run(output=sys.stdout)

A102py = ws.add_job_from_file("themodelv6A102.gms")
A102py.run(output=sys.stdout)

SEH103py = ws.add_job_from_file("themodelv6SEH103.gms")
SEH103py.run(output=sys.stdout)

W103py = ws.add_job_from_file("themodelv6W103.gms")
W103py.run(output=sys.stdout)

A103cpy = ws.add_job_from_file("themodelv6A103c.gms")
A103cpy.run(output=sys.stdout)

A104py = ws.add_job_from_file("themodelv6A104.gms")
A104py.run(output=sys.stdout)

A105py = ws.add_job_from_file("themodelv6A105.gms")
A105py.run(output=sys.stdout)

SEH106py = ws.add_job_from_file("themodelv6SEH106.gms")
SEH106py.run(output=sys.stdout)

W106py = ws.add_job_from_file("themodelv6W106.gms")
W106py.run(output=sys.stdout)

A106dpy = ws.add_job_from_file("themodelv6A106d.gms")
A106dpy.run(output=sys.stdout)

A107py = ws.add_job_from_file("themodelv6A107.gms")
A107py.run(output=sys.stdout)

A108py = ws.add_job_from_file("themodelv6A108.gms")
A108py.run(output=sys.stdout)

A109py = ws.add_job_from_file("themodelv6A109.gms")
A109py.run(output=sys.stdout)

A110py = ws.add_job_from_file("themodelv6A110.gms")
A110py.run(output=sys.stdout)

A111py = ws.add_job_from_file("themodelv6A111.gms")
A111py.run(output=sys.stdout)

A112py = ws.add_job_from_file("themodelv6A112.gms")
A112py.run(output=sys.stdout)

#Begin year 10

SEH113py = ws.add_job_from_file("themodelv6SEH113.gms")
SEH113py.run(output=sys.stdout)

W113py = ws.add_job_from_file("themodelv6W113.gms")
W113py.run(output=sys.stdout)

A113cpy = ws.add_job_from_file("themodelv6A113c.gms")
A113cpy.run(output=sys.stdout)

A114py = ws.add_job_from_file("themodelv6A114.gms")
A114py.run(output=sys.stdout)

SEH115py = ws.add_job_from_file("themodelv6SEH115.gms")
SEH115py.run(output=sys.stdout)

W115py = ws.add_job_from_file("themodelv6W115.gms")
W115py.run(output=sys.stdout)

A115cpy = ws.add_job_from_file("themodelv6A115c.gms")
A115cpy.run(output=sys.stdout)

A116py = ws.add_job_from_file("themodelv6A116.gms")
A116py.run(output=sys.stdout)

A117py = ws.add_job_from_file("themodelv6A117.gms")
A117py.run(output=sys.stdout)

SEH118py = ws.add_job_from_file("themodelv6SEH118.gms")
SEH118py.run(output=sys.stdout)

W118py = ws.add_job_from_file("themodelv6W118.gms")
W118py.run(output=sys.stdout)

A118dpy = ws.add_job_from_file("themodelv6A118d.gms")
A118dpy.run(output=sys.stdout)

SEH119py = ws.add_job_from_file("themodelv6SEH119.gms")
SEH119py.run(output=sys.stdout)

W119py = ws.add_job_from_file("themodelv6W119.gms")
W119py.run(output=sys.stdout)

A119cpy = ws.add_job_from_file("themodelv6A119c.gms")
A119cpy.run(output=sys.stdout)

A120py = ws.add_job_from_file("themodelv6A120.gms")
A120py.run(output=sys.stdout)

SEH121py = ws.add_job_from_file("themodelv6SEH121.gms")
SEH121py.run(output=sys.stdout)

W121py = ws.add_job_from_file("themodelv6W121.gms")
W121py.run(output=sys.stdout)

A121cpy = ws.add_job_from_file("themodelv6A121c.gms")
A121cpy.run(output=sys.stdout)

A122py = ws.add_job_from_file("themodelv6A122.gms")
A122py.run(output=sys.stdout)

SEH123py = ws.add_job_from_file("themodelv6SEH123.gms")
SEH123py.run(output=sys.stdout)

W123py = ws.add_job_from_file("themodelv6W123.gms")
W123py.run(output=sys.stdout)

A123cpy = ws.add_job_from_file("themodelv6A123c.gms")
A123cpy.run(output=sys.stdout)

A124py = ws.add_job_from_file("themodelv6A124.gms")
A124py.run(output=sys.stdout)

#Begin year 11

SEH125py = ws.add_job_from_file("themodelv6SEH125.gms")
SEH125py.run(output=sys.stdout)

W125py = ws.add_job_from_file("themodelv6W125.gms")
W125py.run(output=sys.stdout)

A125cpy = ws.add_job_from_file("themodelv6A125c.gms")
A125cpy.run(output=sys.stdout)

A126py = ws.add_job_from_file("themodelv6A126.gms")
A126py.run(output=sys.stdout)

SEH127py = ws.add_job_from_file("themodelv6SEH127.gms")
SEH127py.run(output=sys.stdout)

W127py = ws.add_job_from_file("themodelv6W127.gms")
W127py.run(output=sys.stdout)

A127cpy = ws.add_job_from_file("themodelv6A127c.gms")
A127cpy.run(output=sys.stdout)

A128py = ws.add_job_from_file("themodelv6A128.gms")
A128py.run(output=sys.stdout)

A129py = ws.add_job_from_file("themodelv6A129.gms")
A129py.run(output=sys.stdout)

SEH130py = ws.add_job_from_file("themodelv6SEH130.gms")
SEH130py.run(output=sys.stdout)

W130py = ws.add_job_from_file("themodelv6W130.gms")
W130py.run(output=sys.stdout)

A130dpy = ws.add_job_from_file("themodelv6A130d.gms")
A130dpy.run(output=sys.stdout)

A131py = ws.add_job_from_file("themodelv6A131.gms")
A131py.run(output=sys.stdout)

A132py = ws.add_job_from_file("themodelv6A132.gms")
A132py.run(output=sys.stdout)

A133py = ws.add_job_from_file("themodelv6A133.gms")
A133py.run(output=sys.stdout)

A134py = ws.add_job_from_file("themodelv6A134.gms")
A134py.run(output=sys.stdout)

A135py = ws.add_job_from_file("themodelv6A135.gms")
A135py.run(output=sys.stdout)

A136py = ws.add_job_from_file("themodelv6A136.gms")
A136py.run(output=sys.stdout)