import numpy as np
from tb_dds import NUM_SAMPLES, PATH, check_equality, to_b

DATA_WIDTH = 32
DEC_WIDTH = 24

NUM_SAMPLES = 10_000
DECIMATION = 100


def main():

    data = np.arange(NUM_SAMPLES)

    with open(PATH + "stimuli.txt", "w") as file:
        file.write(f"{to_b(DECIMATION, DEC_WIDTH)}\n")
        for i in data:
            file.write(f"{to_b(i, DATA_WIDTH)}\n")

    expected = data[::DECIMATION]
    print(f"Num_samples: {NUM_SAMPLES}")
    print(f"Num_results: {len(expected)}")
    try:
        results = np.loadtxt(PATH + "effective_results.txt")
        check_equality(expected, results)
    except FileNotFoundError:
        print("Results file does not exist")


if __name__ == "__main__":
    main()
