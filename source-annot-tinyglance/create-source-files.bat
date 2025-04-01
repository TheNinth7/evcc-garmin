REM Copies the source files from source-annot-glance
REM and replaces the annotations. See README.MD for details.
REM cd .\source-annot-tinyglance\
copy ..\source-annot-glance\*.mc .\
sed -i "s/(:glance) //g" *.mc
sed -i "s/(:glance :background) /(:background) /g" *.mc
del sed*