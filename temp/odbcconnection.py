import pyodbc
drv = pyodbc.drivers()
print (len(drv))
for d in drv:
  print(d)
# Create connection
try:
  con = pyodbc.connect(driver="{SQL Server}",server='krmpn1.database.windows.net',database='kr_redcustom1',uid='krish',pwd='Kr1sh234')
  cur = con.cursor()
  db_cmd = "drop table load_one.load_Orders"
  res = cur.execute(db_cmd)
  con.commit()
  # Do something with your result set, for example print out all the results:
 # for r in res:
   #   print(r)
except pyodbc.Error as e:
    print(e)
