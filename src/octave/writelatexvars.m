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
## @var{V} is a (scalar) structure containing the variables to be exported,
## with each variable as a single field. The fieldnames become the names
## of the exported variables.
## The value can be any scalar or string. Strings are exported as-is, while
## other values are formatted depending on their type.
##
## It is worth noting that if none of the available formats is desirable,
## one can still format the variable as needed and store it as a string.
## @end deftypefn
function writelatexvars(file, V)
	% Get file handle
	if (ischar(file))
		ensure_dir_exists(file);
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

	% TODO: Support specifying value rendering? E.g by passing a cell array
	% like {value, "format/type"}?
	if (isstruct(V))
		if (length(V) > 1)
			error(["The input must be a scalar structure, " ...
					"not a structure array"]);
		endif
		fdisp(f, '% This file was created by Octave (https://www.octave.org/).');
		fdisp(f, '% To include it in your LaTeX file, use \input{path/to/this/file.tex}.');
		fdisp(f, '%');
		fdisp(f, '% To create a similar file, see function "writelatexvars" from');
		fdisp(f, '% https://github.com/Singond/Octave-report.');
		% Input is key-value pairs
		for [val, name] = V;
			% TODO Handle different types
			if (ischar(val))
				valstr = val;
			elseif (isscalar(val))
				if(isreal(val))
					valstr = sprintf("%g", val);
				elseif(iscomplex(val))
					valstr = sprintf("%g + %g%s", real(val), imag(val), imagunit);
				else
					error("Variable '%s' is of unsupported scalar type (%s)", ...
						name, typeinfo(val));
				endif
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
