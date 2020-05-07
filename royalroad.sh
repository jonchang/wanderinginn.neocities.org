#!/bin/sh

curl -LO https://github.com/Aivean/royalroad-downloader/releases/download/2.1.0/royalroad-downloader-assembly-2.1.0.jar
java -jar royalroad-downloader-assembly-2.1.0.jar https://www.royalroad.com/fiction/10073/the-wandering-inn
rm royalroad-downloader-assembly-2.1.0.jar
