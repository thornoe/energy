import matplotlib.pyplot as plt
from numpy.random import randn

xvals = range(10)
means = [len(xvals) - i - randn() for i in xvals]
upper = [m + 1 for m in means]
lower = [m - 1 for m in means]

fig = plt.figure()
ax = fig.add_subplot(111)
ax.scatter(xvals, means, color = 'black')
for x, low, high in zip(xvals, lower, upper):
    ax.plot([x,x], [low, high], color = 'black')
