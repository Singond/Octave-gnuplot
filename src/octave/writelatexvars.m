## -*- texinfo -*-
## @deftypefn {Function File} {} writelatexvars(@var{file}, @var{V})
##
## Export variables into new LaTeX macro definitions. The variables are
## written to a standalone @code{.tex} file, which can be @code{input}
## into another LaTeX document.
##
## @var{file} can be a filename or a file handle. If it is a filename, a file
## with this name is written.
##
## @end deftypefn
function writelatexvars(file, V)
	% Get file handle
	if (ischar(file))
		f = fopen(file, "w");
		fprivate = 1;
	elseif (is_valid_file_id(file))
		% 'f' is a file handle
		f = file;
		fprivate = 0;
	else
		print_usage();
	endif

#	imagunit = '\mathrm{i}';
	imagunit = 'i';
	if (isstruct(V))
		if (length(V) > 1)
			error(["The input must be a scalar structure, " ...
					"not a structure array"]);
		endif
		% Input is key-value pairs
		for [val, name] = V;
			% TODO Handle different types
			if (isscalar(val))
				if (isinteger(val))
					valstr = sprintf("%d", val);
				elseif(isreal(val))
					valstr = sprintf("%g", val);
				elseif(iscomplex(val))
					valstr = sprintf("%g + %g%s", real(val), imag(val), imagunit);
				else
					error("Variable '%s' is of unsupported scalar type (%s)", ...
						name, typeinfo(val));
				endif
			elseif (ischar(val))
				valstr = val;
			else
				error("Variable '%s' is of unsupported type (%s)", ...
						name, typeinfo(val));
			endif
			fprintf(f, '\\newcommand\\%s{%s}\n', name, valstr);
		endfor
	else
		error("'V' must be a scalar structure, got %s", typeinfo(V));
	endif

	% Clean up if the file was created in this function
	if (fprivate)
		fclose(f);
	endif
endfunction
