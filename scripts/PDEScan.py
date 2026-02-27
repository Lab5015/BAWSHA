#----------------------------------------------------------------
#1. Solve PDE for PlanoConvex, SingleStep and MultiStep Profiles
#2. Save results in txt file
#----------------------------------------------------------------

from Helmoltz.src.Utils.EWE import *
import numpy as np
import os
import logging

#------------------------------------------------------------
# Save Paths
#------------------------------------------------------------
Modes_PNG = r"E:\Riccardo\BAUSCIA\Helmoltz\RUNS\RUN3\Modes_PNG"
CR_PNG    = r"E:\Riccardo\BAUSCIA\Helmoltz\RUNS\RUN3\CR_PNG"
RM_PNG    = r"E:\Riccardo\BAUSCIA\Helmoltz\RUNS\RUN3\RM_PNG"
CR_RES    = r"E:\Riccardo\BAUSCIA\Helmoltz\RUNS\RUN3\CR_RES"
RM_RES    = r"E:\Riccardo\BAUSCIA\Helmoltz\RUNS\RUN3\RM_RES"
RUNS      = r"E:\Riccardo\BAUSCIA\Helmoltz\RUNS\RUN3"

# ------------------------------------------------------------
# Create directories 
# ------------------------------------------------------------
os.makedirs(CR_RES, exist_ok=True)
os.makedirs(RM_RES, exist_ok=True)
os.makedirs(CR_PNG, exist_ok=True)
os.makedirs(RM_PNG, exist_ok=True)
os.makedirs(Modes_PNG, exist_ok=True)

# ------------------------------------------------------------
# Logger setup
# ------------------------------------------------------------
log_file = os.path.join(RUNS, "run.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    handlers=[
        logging.FileHandler(log_file, mode="w"),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger()
logger.info("Starting parameter scan")

# ------------------------------------------------------------
# Create cumulative database file
# ------------------------------------------------------------
db_path = os.path.join(RUNS, "fit_database.txt")
db_file = open(db_path, "w")
db_file.write("h\tRin\tCR1\tCR2\tCR3\tRM1\tRM2\tRM3\n")
logger.info("Database file for popt created")

db_path1 = os.path.join(RUNS, "results_database1.txt")
db_file1 = open(db_path1, "w")
db_file1.write("h\tRin\tCR1N1\tCR2N1\tCR3N1\tRM1N1\tRM2N1\tRM3N1\n")
logger.info("Database file for results N=1 created")

db_path2 = os.path.join(RUNS, "results_database3.txt")
db_file2 = open(db_path2, "w")
db_file2.write("h\tRin\tCR1N3\tCR2N3\tCR3N3\tRM1N3\tRM2N3\tRM3N3\n")
logger.info("Database file for results N=3 created")

#------------------------------------------------------------
# Geometrical Constants & Grid
#------------------------------------------------------------
L0 = 9
eps = 1e-6
D = Laplacian()
grid = {
    "h_values" : np.linspace(1/8, 2/3, 15)*L0,
    "Rin_values" : np.linspace(1/8, 2/3, 15)*Rout,
}
counter = 0
#------------------------------------------------------------
# Solve PDE and save results
#------------------------------------------------------------
for h in grid["h_values"]:
    for Rin in grid["Rin_values"]:
        counter+=1

        logger.info(f"Solving PDE for h={h:.4f}, Rin={Rin:.4f}")
        logger.info(f"Missing combinations are {len(grid["h_values"])*len(grid["Rin_values"])- counter}")

        try:
            results_pc = solve_PDE('PC', D, L0, h, Rin, eps)
            CRN1_pc = results_pc["CR"][0]# get CR for N=3
            RMN1_pc = resonant_mass(results_pc["HWHM"][0], L0)# get RM for N=3
            CRN3_pc = results_pc["CR"][1]# get CR for N=3
            RMN3_pc = resonant_mass(results_pc["HWHM"][1], L0)# get RM for N=3
            
            results_sp = solve_PDE('SP', D, L0, h, Rin, eps)
            CHECK = check_under_profile(pc(rho, L0, h), results_sp)
            if CHECK:
                logger.info("Mode is under profile")       
                CRN1_sp = results_sp["CR"][0]# get CR for N=3
                RMN1_sp = resonant_mass(results_sp["HWHM"][0], L0)# get RM for N=3
                CRN3_sp = results_sp["CR"][1]# get CR for N=3
                RMN3_sp = resonant_mass(results_sp["HWHM"][1], L0)# get RM for N=3
            else:
                logger.warning("Mode is NOT under profile")  
                pass     
            
            
            results_ms = solve_PDE('MS', D, L0, h, Rin, eps)
            CHECK = check_under_profile(pc(rho, L0, h), results_sp)
            if CHECK:
                logger.info("Mode is under profile")
                CRN1_ms = results_ms["CR"][0]# get CR for N=3
                RMN1_ms = resonant_mass(results_ms["HWHM"][0], L0)# get RM for N=3
                CRN3_ms = results_ms["CR"][1]# get CR for N=3
                RMN3_ms = resonant_mass(results_ms["HWHM"][1], L0)# get RM for N=3
            else:
                logger.warning("Mode is NOT under profile")

            plot_modes(
                results_pc, results_sp, results_ms,
                L0, Rin, h, eps,
                False,
                Modes_PNG + f"/Modes_h_{h:.4f}_Rin_{Rin:.4f}",
                False
            )

            CR1, CR2, CR3 = fit_CR(
                results_pc, results_sp, results_ms,
                save_plot=False,
                plot=False,
                save_path=CR_PNG + f"/CR_h_{h:.4f}_Rin_{Rin:.4f}"
            )

            HW1, HW2, HW3 = fit_RM(
                results_pc, results_sp, results_ms,
                L0,
                save_plot=False,
                plot=False,
                save_path=RM_PNG + f"/RM_h_{h:.4f}_Rin_{Rin:.4f}"
            )

            # ------------------------------------------------------------
            # Save fit results
            # ------------------------------------------------------------
            cr_filename = os.path.join(CR_RES, f"CR_h_{h:.4f}_Rin_{Rin:.4f}.txt")
            rm_filename = os.path.join(RM_RES, f"RM_h_{h:.4f}_Rin_{Rin:.4f}.txt")

            # ------------------------------------------------------------
            # Append results to database
            # ------------------------------------------------------------
            db_file.write(
                    f"{h:.8e}\t{Rin:.8e}\t"
                    f"{arr_to_str(CR1)}\t{arr_to_str(CR2)}\t{arr_to_str(CR3)}\t"
                    f"{arr_to_str(HW1)}\t{arr_to_str(HW2)}\t{arr_to_str(HW3)}\n"
                )
            db_file.flush()   
            
            db_file1.write(
                    f"{h:.8e}\t{Rin:.8e}\t"
                    f"{CRN1_pc}\t{CRN1_sp}\t{CRN1_ms}\t"
                    f"{RMN1_pc}\t{RMN1_sp}\t{RMN1_ms}\n"
                )
            db_file1.flush() 
            
            db_file2.write(
                    f"{h:.8e}\t{Rin:.8e}\t"
                    f"{CRN3_pc}\t{CRN3_sp}\t{CRN3_ms}\t"
                    f"{RMN3_pc}\t{RMN3_sp}\t{RMN3_ms}\n"
                )
            db_file2.flush()   

            logger.info(f"Completed h={h:.4f}, Rin={Rin:.4f}")
            logger.info(f"CRs: {CR1}, {CR2}, {CR3}")
            logger.info(f"RMs: {HW1}, {HW2}, {HW3}")

        except Exception as e:
            logger.error(f"Error for h={h:.4f}, Rin={Rin:.4f}")
            logger.exception(e)
            
db_file.close()
db_file1.close()
db_file2.close()
logger.info("Parameter scan completed")