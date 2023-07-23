# aegis-lua-scripts
## Groupcopy
It allows you to copy all the start tag from N to N lines.<br />
You can also check if you want to overwrite existent tags, keep inline and/or old start tags from lines on which tags will be copied.<br />
<br />
For make this script works, you must select all the lines from which tags will be copied, and the lines on which tags will be copied, separated at least by one commented line.<br />
To separate the lines "to be copied from" and the lines "to be copied to", put a commented line wich only contains "--end".<br />
<br />
### This script can:
  - copy start tags from 1 to n lines * x

Example:<br />
{\b1} (copy from)<br />
{\fad(300,400)} (copy from)<br />
commented lines (separator) text = ""--end<br />
(first group of lines (1), \b will be copied here)<br />
(first group of lines (2), \b will be copied here)<br />
commented lines (separator)<br />
(second group of lines (1), \fad(300,400) will be copied here)<br />
(second group of lines (2), \fad(300,400) will be copied here)<br />
(second group of lines (3), \fad(300,400) will be copied here)<br />

 - copy start tags from n to n lines * x

Example:<br />
{\b1} (copy from)<br />
{\i1} (copy from)<br />
commented lines (separator)<br />
{\u1} (copy from)<br />
{s1} (copy from)<br />
commented lines (separator) text = ""--end<br />
(first group of lines (1-1), \b1 will be copied here)<br />
(first group of lines (1-2), \i1 will be copied here)<br />
commented lines (separator)<br />
(second group of lines (2-1), \u1 will be copied here)<br />
(second group of lines (1-1), \s1 will be copied here)<br />

Obviously, you can copy more than one tag for group.<br />
Having said that, have fun.
