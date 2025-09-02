import csv
import xlrd
import os

if __name__=='__main__':

    data_dir="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/6m"
    for file in os.listdir(data_dir):
        if file.endswith(".xlsm"):
            (fname,ext)=os.path.splitext(file)
            workbook = xlrd.open_workbook(os.path.join(data_dir,file))
            block_num=1
            for idx,sheet in enumerate(workbook.sheets()):
                fout_name=os.path.join(data_dir,'%s_trial_times.csv' % fname)
                if idx>0:
                    if sheet.row_values(0)[0]=='Directions':
                        continue
                    fout_name=os.path.join(data_dir,'%s_block_%d.csv' % (fname,block_num))
                    block_num+=1
                f=open(fout_name,'wb')
                writer = csv.writer(f)
                writer.writerows(sheet.row_values(row) for row in range(sheet.nrows))
                f.close()

    data_dir="/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/preferential_gaze/9m"
    for file in os.listdir(data_dir):
        if file.endswith(".xlsm"):
            (fname,ext)=os.path.splitext(file)
            workbook = xlrd.open_workbook(os.path.join(data_dir,file))
            block_num=1
            for idx,sheet in enumerate(workbook.sheets()):
                fout_name=os.path.join(data_dir,'%s_trial_times.csv' % fname)
                if idx>0:
                    if sheet.row_values(0)[0]=='Directions':
                        continue
                    fout_name=os.path.join(data_dir,'%s_block_%d.csv' % (fname,block_num))
                    block_num+=1
                f=open(fout_name,'wb')
                writer = csv.writer(f)
                writer.writerows(sheet.row_values(row) for row in range(sheet.nrows))
                f.close()