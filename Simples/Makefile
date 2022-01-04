# See simples-export.org for context
%-export.bash: %.bash
	echo '# * Created by make, do not edit' > $@
	echo '# ** Source the original file' >> $@
	echo . "'$<'" >> $@
	echo '# ** Export Global Variables' >> $@
	sed -n 's/^\([a-zA-Z][a-zA-Z0-9_]*\)=.*/export \1/p' $< >> $@
	echo '# ** Export Functions' >> $@
	sed -n 's/^\([a-zA-Z][a-zA-Z0-9_]*\)().*/export -f \1/p' $< >> $@
