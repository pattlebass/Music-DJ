from os import listdir
from os.path import isfile, join
from os import getcwd
from bs4 import BeautifulSoup
import argparse

parser = argparse.ArgumentParser(description='Provide all the SVG attributes needed for MusicDJ.')
parser.add_argument('--fill', type=str, default="#000000", metavar="COLOR", help='adds the fill attribute with the specified color (in HEX, with #)')

args = parser.parse_args()


for path in listdir(getcwd()):
    if isfile(join(getcwd(), path)) and path.endswith(".svg"):
        file = open(path, "r")
        svg_string = file.read()
        file.close()

        soup = BeautifulSoup(svg_string, "xml")
        svg = soup.find("svg")
        
        svg["fill"] = args.fill

        if not "viewBox" in svg.attrs:
            svg["viewBox"] = "0 0 24 24"
            print(path + ": added viewbox")

        if svg["height"] != "36" or svg["width"] != "36":
            svg["height"] = "36"
            svg["width"] = "36"
            print(path + ": set dimentions")
        
        file = open(path, "w")
        file.write(str(svg))
        file.close()
