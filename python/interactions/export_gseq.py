import os

def write_stream(outfile, current_stream):
    sorted_stream=sorted(current_stream, key=lambda tup: tup[0])
    stream_str=''
    for idx,(time_sec,code) in enumerate(sorted_stream):
        time_min=int(time_sec/60)
        sec_rem=time_sec-time_min*60
        whole_sec=int(sec_rem)
        ms=int((sec_rem-whole_sec)*1000)

        next_time_sec=time_sec+1.0/25.0
        if idx<len(sorted_stream)-1 and next_time_sec>sorted_stream[idx+1][0]:
            next_time_sec=sorted_stream[idx+1][0]
        next_time_min=int(next_time_sec/60)
        next_sec_rem=next_time_sec-next_time_min*60
        next_whole_sec=int(next_sec_rem)
        next_ms=int((next_sec_rem-next_whole_sec)*1000)
        stream_str+='%s,%d:%d.%03d-%d:%d.%03d\n' % (code,time_min,whole_sec,ms,next_time_min,next_whole_sec,next_ms)
    outfile.write(stream_str)

def export_coded_interaction_data(data_dir, age, subject_ids, coder):
    outfilename=os.path.join(data_dir, '%s_%s.sds' % (age, coder))
    outfile=open(outfilename,'w')
    outfile.write('Timed ($infant_target = InfantHeadturn InfantPerToyRight InfantRightToy InfantFrontToyRight '
                  'InfantFrontToyLeft InfantLeftToy InfantPerToyLeft InfantMotherface InfantMotherhand InfantMotherbody '
                  'InfantOwnhand InfantOwnfoot InfantOwnbody InfantCamera InfantHighchair InfantOtherambig) '
                  '($infant_horiz_dir InfantBack InfantBackRight InfantFarRight InfantMidRight InfantNearRight '
                  'InfantCentre InfantNearLeft InfantMidLeft InfantFarLeft InfantBackLeft) '
                  '($infant_vert_dir InfantUp InfantMiddle InfantDown) '
                  '($mother_target = MotherHeadturn MotherRearToyRight MotherPerToyRight MotherFrontToyRight '
                  'MotherFrontToyLeft MotherPerToyLeft MotherRearToyLeft MotherInfantface MotherInfanthand '
                  'MotherInfantfoot MotherInfantbody MotherOwnhand MotherOwnbody MotherCamera MotherHighchair MotherOtherambig) '
                  '($mother_horiz_dir MotherBack MotherBackRight MotherFarRight MotherMidRight MotherNearRight '
                  'MotherCentre MotherNearLeft MotherMidLeft MotherFarLeft MotherBackLeft) '
                  '($mother_vert_dir MotherUp MotherMiddle MotherDown);\n')
    for subj_id in subject_ids:
        filename=os.path.join(data_dir, '%d_%s_%s.csv' % (subj_id,age,coder))

        file=open(filename,'r')
        current_stream=[]
        frames=[]
        prefix=''
        streams_written=0
        for idx,l in enumerate(file):
            #cols=line.replace('\n','').split(',')
            lines=l.split('\n')
            ended=False
            for line in lines:
                #cols=line.replace('\n','').split(',')
                cols=line.split(',')
                if len(cols)>1:
                    if cols[0]=='1':
                        frames=cols[2:]
                    elif cols[0]=='Infant' or cols[0]=='Mother':
                        if len(current_stream):
                            if streams_written>0:
                                outfile.write('&\n')
                            write_stream(outfile, current_stream)
                            streams_written+=1
                        current_stream=[]
                        prefix=cols[0]
                    elif cols[1]=='Level 2':
                        ended=True
                        break
                    elif len(cols[1]):
                        code='%s%s' % (prefix,cols[1].replace(' ','').replace('/',''))
                        if code=='InfantHeadturn' or code=='InfantBack' or code=='InfantUp' or code=='MotherHeadturn' or\
                           code=='MotherBack' or code=='MotherUp':
                            if len(current_stream):
                                if streams_written>0:
                                    outfile.write('&\n')
                                write_stream(outfile, current_stream)
                                streams_written+=1
                            current_stream=[]
                        for idx in range(2,len(cols)):
                            if cols[idx]=='x':
                                time=float(frames[idx-2])/25.0
                                current_stream.append((time,code))
            if ended:
                break
        if streams_written>0:
            outfile.write('&\n')
        write_stream(outfile, current_stream)
        streams_written+=1
        outfile.write('/\n')
        file.close()
    outfile.close()


if __name__=='__main__':
    export_coded_interaction_data('/data2/Dropbox/joint_attention/infant_gaze_eeg-interactions/data/ben_coding/reliability', '6.5m', [117,121], 'HR')
    export_coded_interaction_data('/data2/Dropbox/joint_attention/infant_gaze_eeg-interactions/data/ben_coding/reliability', '6.5m', [117,121], 'BH')
