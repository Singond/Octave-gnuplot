## Enables controlling Gnuplot from within Octave.
## While Octave supports Gnuplot natively, it abstracts from its details and makes
## fine-grained control over the final result difficult. This utility aims to fill
## this gap by providing more direct control over what is being passed to Gnuplot.
##
## Requires `gnuplot` to be installed and available on `PATH`.

classdef gnuplotter < handle
	properties (Access = private)
		## The gnuplot process
		gp
		## Default plot to be used when plotdef functions are invoked
		## directly on this object.
		plt
		## A list of all plotdefs sharing this gnuplot process
		allplots = cell();
		## Plots to be plotted in multiplot
		mplot
	endproperties

	methods
		function obj = gnuplotter()
			disp("Starting new gnuplot process");
			obj.gp = popen("gnuplot", "w");
			obj.plt = obj.newplot();
		endfunction

		function p = newplot(obj)
			p = gnuplotdef(obj.gp);
			obj.allplots = [obj.allplots {p}];
		endfunction

		## usage: exec(command)
		##
		## Executes arbitraty gnuplot command.
		function exec(obj, cmdline)
			fputs(obj.gp, [cmdline "\n"]);
		endfunction

		function load(obj, filename)
			fputs(obj.gp, sprintf("load '%s'\n", filename));
		endfunction

		## Passes numerical data directly to gnuplot.
		function data(obj, D)
			fmt = [repmat('%g ', [1 columns(D)])(1:end-1) "\n"];
			fprintf(obj.gp, fmt, D');
			fputs(obj.gp, "e\n");
		endfunction

#		function defaultxlabel(obj, label)
#			fputs(obj.gp, sprintf("set xlabel \"%s\"\n", label));
#		endfunction
#
#		function defaultylabel(obj, label)
#			fputs(obj.gp, sprintf("set ylabel \"%s\"\n", label));
#		endfunction
#
#		function defaulttitle(obj, title)
#			fputs(obj.gp, sprintf("set title \"%s\"\n", title));
#		endfunction

		function multiplot(obj, a, b, c)
			if (nargin < 2)
				error("Not enough arguments");
				#print_usage();     # Not working in classdef?
				return;
			elseif (isinteger(a))
				## First form: only set layout grid
				rows = a;
				cols = rows;
				cmd = "";
				if (nargin > 2)
					if (isinteger(b))
						cols = b;
					elseif (ischar(b))
						cmd = b;
					else
						#arg error
					endif
				elseif(nargin == 4)
					cols = b;
					cmd = c;
				else
					#arg error
				endif
				fprintf(obj.gp, "set multiplot layout %d,%d %s\n", ...
						rows, columns, cmd);
			elseif (iscell(a))
				## Set plot definitions as individual plots
				if (nargin == 2)
					cmd = "";
				elseif(nargin == 3)
					cmd = b;
				else
					#arg error
				endif
				s = size(a);
				if (length(s) != 2)
					error("cell must be a 2D cell array");
				endif
				fprintf(obj.gp, "set multiplot layout %d,%d %s\n", ...
						s(1), s(2), cmd);
				obj.mplot = a;
			else
				#arg error
			endif
		endfunction

		function singleplot(obj)
			fprintf(obj.gp, "unset multiplot\n");
			clear obj.mplot;
		endfunction

		## Draws plot according to specifications and data given in `plot`.
		function doplot(obj)
			if (obj.mplot)
				## Do multiplot
			else
				obj.plt.doplot();
			endif
		endfunction

		##--------------------------------------------------------------
		## Plotdef functions to be delegated to the default plot
		##--------------------------------------------------------------

		function xlabel(obj, label)
			obj.plt.xlabel(label);
		endfunction

		function ylabel(obj, label)
			obj.plt.ylabel(label);
		endfunction

		function title(obj, title)
			obj.plt.title(title);
		endfunction

		function plot(obj, D, style="")
			obj.plt.plot(D, style);
		endfunction

		function clearplot(obj)
			obj.plt.clearplot();
		endfunction

		function export(obj, file, term, options)
			obj.plt.export(file, term, options);
		endfunction

		function disp(obj)
			disp("gnuplotter");
		endfunction

		##--------------------------------------------------------------
		## End of delegated plotdef functions
		##--------------------------------------------------------------

		## DEPRECATED. Will be renamed to 'delete' in future release, once
		## the destructor methods on classdef objects work correctly
		## (this may already be true in Octave 5).
		## In Octave version 4.4, renaming this method to 'delete' and calling
		## it implicitly by the 'clear' command does not work, because the 'gp'
		## field is destroyed even before invoking 'delete'.
		function deletex(obj)
			for i = 1:length(obj.allplots)
				clear obj.allplots{i};
			endfor
			disp("Closing gnuplotter");
			fputs(obj.gp, "exit\n");
			pclose(obj.gp);
		endfunction
	endmethods

	methods (Static = true)
		function D = datamatrix(X, Y)
			if (!isnumeric(X))
				error("X must be a numeric value");
			elseif (!isnumeric(Y))
				error("Y must be a numeric value");
			endif
			# TODO Check for size compatibility
			D = [X(:) Y(:)];
		endfunction
	endmethods
endclassdef
