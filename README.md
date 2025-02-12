<p align="center">
  <img src="https://github.com/user-attachments/assets/a45ab18f-2f2c-4690-b3e7-663d78f2821f"/>
</p>

</p>
<p align="center">
    <a href="https://github.com/sof202/ChromCompare/commits/main/" alt="Commit activity">
        <img src="https://img.shields.io/github/commit-activity/m/sof202/ChromCompare?style=for-the-badge&color=blue" /></a>
    <a href="https://github.com/sof202/ChromCompare/blob/main/LICENSE" alt="License">
        <img src="https://img.shields.io/github/license/sof202/ChromCompare?style=for-the-badge&color=blue" /></a>
</p>

When generating models with [ChromHMM](https://compbio.mit.edu/ChromHMM/) for
different cell types (or tissues), one of your goals might be to see which
states are shared across models. ChromHMM has a solution for this with the
`CompareModels` command, which looks at the correlation in the emission
parameters for each state.

However, this command is not very useful in my opinion. Firstly, ChromHMM tells
you *if* a state has an analagous state in a different model (not which one).
Then, much more importantly, it doesn't take into account that a model might
have multiple states that are very similar in terms of their emission
parameters. Some of your models may have states that appear similar in emission
parameters, but are spatially very different. Such states are different, but
would be correlated with states in the comparison model that they shouldn't be.
If you had an abundance of epigenetic datasets to work with, these states that
possess similar emission parameters may start to separate to the point where
spatial properties are not required to compare across models. However, an
abundance of datasets is not usually feasible.

In order to solve this problem ChromCompare takes into account both the
emission parameters and the spatial properties of the state's assignment on the
genome. This way, users can make much more informed decisions about which
states are shared between two models, and which ones are unique to only one.
Knowing this information can be very useful when looking for cell type or
tissue type differences.

## Setup

In order to run ChromCompare, you must first complete the required setup steps
highlighted below:

1) Download all [required software](#required-software)
2) Fill in the configuration file found in `.../Setup` and place this file
in a memorable location (you can just leave it in the Setup directory if you
wish). You can also change the name of the file if you think you will have
multiple configuaration files.
3) Run the main `ChromCompare.sh` script (found in `JobSubmission`) with
Slurm Workload Manager, provide the full path to the config file as the first
and only argument to the script.

An example of running the main script would be:

```bash
sbatch .../ChromCompare.sh .../path/to/configuration_file.txt
```

For additional information it is recommended that you read the 
[documentation](https://sof202.github.io/ChromCompare/).

## Required Software

ChromCompare requires the following software in order to run:
Ensure that these software can be found on your `PATH` environment variable,
*i.e.* you can run these from the command line directly (for example, `conda
...`).

- [bash](https://www.gnu.org/software/bash/) (>=4.2.46(2))
- [SLURM Workload Manager](https://slurm.schedmd.com/overview.html) (>=20.02.3)
- [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) (>=v23.10.0)
- [python](https://www.python.org) (>= 3.10.0)
  - This should be available if you have conda installed.
