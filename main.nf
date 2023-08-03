nextflow.enable.dsl=2

def run_dir_path = "/scratch/eb167/gencore_tar/s/gencore/sequencers/NB502067/230523_NB502067_0551_AHG2CHAFX5"
def run_dir_name = new File(run_dir_path).getName()
def parts = run_dir_name.split('_')
def seq_id = parts[1]

def fcid = ""

def fcidPart = parts[3]
if (fcidPart.startsWith("A") || fcidPart.startsWith("B")) {
        fcid = fcidPart.substring(1)
} else {
        fcid = fcidPart
}

def lane = 1

process getFiles {
  conda 'rsync'
  debug true

  output:
  path '${params.run_dir_name}'

  rsync -rav eb167@dtn.hpc.nyu.edu:${params.run_dir_path} . 

}


process picard {
  conda 'picard=2.27.5'
  debug true
  
  input:
    path x 
  
  """
read_structure=\$(python3 -c "
import xml.dom.minidom

read_structure = ''
runinfo = xml.dom.minidom.parse('${x}/RunInfo.xml')
nibbles = runinfo.getElementsByTagName('Read')

for nib in nibbles:
  read_structure += nib.attributes['NumCycles'].value + 'T'

print(read_structure)
")

run_barcode=\$(python3 -c "
print('${x}'.split('_')[-2].lstrip('0'))
")

picard -Xmx20g IlluminaBasecallsToFastq \
        LANE=1 \
        READ_STRUCTURE=\${read_structure} \
        BASECALLS_DIR=${x}/Data/Intensities/BaseCalls \
        OUTPUT_PREFIX=/nextflow/work/picard_out \
        RUN_BARCODE=\${run_barcode} \
        MACHINE_NAME=${seq_id} \
        FLOWCELL_BARCODE=${fcid} \
        NUM_PROCESSORS=${task.cpus} \
        APPLY_EAMSS_FILTER=false \
        INCLUDE_NON_PF_READS=false \
        MAX_READS_IN_RAM_PER_TILE=200000 \
        MINIMUM_QUALITY=2 \
        COMPRESS_OUTPUTS=true
  """
}

workflow 
  getFiles()
//  picard(getFiles.out)
}
