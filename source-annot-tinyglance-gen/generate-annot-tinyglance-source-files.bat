REM Copies the source files from source-annot-glance
REM and replaces the annotations. See README.MD for details.
REM cd .\source-annot-tinyglance\
cd ..
robocopy .\source-annot-glance .\source-annot-tinyglance /MIR
REM copy ..\source-annot-glance\*.mc .\
cd .\source-annot-tinyglance
for /R %%f in (*.mc) do sed -i "s/(:glance) //g" "%%f"
for /R %%f in (*.mc) do sed -i "s/(:glance :background) /(:background) /g" "%%f"
del sed*