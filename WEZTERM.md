## Wezterm key bind

> [!NOTE]<br>
> How to install wezterm can be found here [Wezterm install](https://wezfurlong.org/wezterm/installation.html)

&nbsp;
Install Wezterm configuration

```bash
git clone https://github.com/RomanAverin/dotfiles
stow -v -R -t ~ wezterm
```

&nbsp;
**Leader** key is the **ctrl + space** key

| conbination | command                                                    |
| ----------- | ---------------------------------------------------------- |
| Leader + c  | copy section to clipboard                                  |
| Leader + v  | paste section from clipboard                               |
| Leader + t  | new tab                                                    |
| Leader + w  | close current tab\pane                                     |
| Leader + n  | new window                                                 |
| Leader + -  | split window horizontal                                    |
| Leader + \  | split window vertical                                      |
| Leader + l  | luncher                                                    |
| Leader + s  | new workspace with random name                             |
| Leader + f  | fuzzy find workspace                                       |
| Leader + e  | rename workspace                                           |
| Leader + r  | resize mode for the pane (hjkl or arrow key to resize)     |
| Leader + a  | move mode for the pane (hjkl or arrow key to move between) |
| Leader + i  | itentity pane/tab                                          |

<p align="center">
<b>Wezterm</b> screenshot
<img src="./wezterm.png">
</p>
&nbsp;
