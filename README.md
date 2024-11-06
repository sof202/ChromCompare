# ChromCompare

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
