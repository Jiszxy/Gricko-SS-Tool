<#
    Gricko SS Tool - Minimalist Ocean-Style Automated Screenshare GUI
    Compact Floating Window with Fishbone Logo, Deep Multi-Instance Scan, Dynamic Client/Instance Selector & Full Mods Browser
#>

function Show-GrickoGui {
    param(
        [int]$HoursPrefetch = 168,
        [int]$HoursFiles = 72,
        [int]$HoursBAM = 168
    )

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    $logoBase64 = "iVBORw0KGgoAAAANSUhEUgAAAdwAAAEHCAYAAAAEWvcZAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAABweSURBVHhe7d37lyxVecZxRSDcxCM3AVEQEBEMIkEuggQRFQ+EICK3RVyIoIAECQKBIyHcliIiMfkT81N+zH+QPDU+PVbveau7qrv23lXd389az1pnuvfe79s9VV1nZrqrPgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAmLr//p//PeZ/AgCAHHSwvUF5zV8CAIAcdLD9P+VhfwkAAMamA+1pPuDe75tmQz3za3AAwDz4YNvkPt80G03f/icAANPWOuD+yDfNgnt+2l8CADBdOmB92weuJo/75slTr8fd85d8EwAA0+WD1qwOuOrz5FbPvhUAgAlrHbiazOJXyu2efRMAANOlA9ad7YOX8pDvmiz1eEu7Z98MANhHOhDc7X9OWvvA5Uz+DUhJv8/7ZgDAPmoOBv7npCUHryYv+q5JUn9PJf2e77sAAPtGB4Gzm4OBv5ws9Xi7D1rtvOy7Jynt1zcDAPaRDgQ/9QHhDN80ServI/fZzpu+e3LU24mkVw64ALDPWgeEG33TJLX6bOffffekqK+zkj4P4rsBAPuodUB4xTdNjno71uqznQ88ZFLU14dJn00+9N0AgH2jg8DSgcw3T456e67dZzseMilRn8qDvhsAsG90ELi5fVDwzZPT7jGNh0yGevpT2qNziYcAAPaNDgJPJweF83zXpCQ9LsVDJiPqsYnvBgDsIx0I/pwcGCZ5ubukx6V4yCSon2fT/hbxkFlQv59TLveXAIBttQ8Izh9812Sopx8nPS7FwyYh6m8RD5k89XpwVSN/CQAYQ/uAsIjvmoyox3Y8rDr1clvaWyuT/PhSSn0u/sRwu28CAIzBL65L8V2TEfXYjodVF/XWysMeNlnq8bVFv74JADAGvbBeuHiBTXKlh0xC0N9SPKwq9XFB2leSr3noJKm/F1u98vElABiTXljvaL3ItvOqh1SnXg7O87wqHlqV+ngr7SvJWR46Oept6Z3qvhkAdoNe2L7sf1ajHp5ov9C24yHVqZfoggVL8dCqor7a8bDJUW/3J72+7rsAYP78wlb9wunq4fBvdmk8pDr10v5VZxgPrUY9XJf2lMZDJ0V9XTGHPgFgI60Xt5t8UzXqIbr6zkE8pLqotzQeWk3UUxoPnQz1dF7aYxPfDQDzpRezc5MXt8/7rmqSftLc72FVBX0diYdWE/WU5F0PnYygxyZX+24AmCe9kEV/h6z+Jpqgp6V4WFVRX0FO9fDiVPuSpJcoP/bwSQj6O4jvBoB50gtZ+qaURU72kGqCnpbiYdWoh9PSnjpymacUF/QS5aseXp16eS/pbZE3PAQA5kcvYumFAdqp9lPZQtBTmmMeWoXqX57005XbPKW4oJcok/hIkPq4OOmrnerbIwBsRC9gbyYvaGnmcMD9vodWofprPxLkPO4pRanuupNdHMTDq4t6W8RDAGBe9AL2TvqCFmQOB9yqL8Sq3/Xr+DT/5ilFqe5jSR9hPLyqqK9WvuthADAfevH6MHkx68oZnlJN0NOReGgVqv+LtJ+ueEpRUR9RPLwa9fBg2lM7HgYA8xG9mK3IxZ5WTdBTlGofX1LtE0kvnfGUoqI+onh4NVFP7XgYAMxD9EK2Jtd5ajVBT1F+6uHFqXbf3xYUP2io5rVpD13xlCqifpKc76EAMH3Bi1if3OXp1QQ9hfHw4qJeuuIpxahm3193v+8pxan21UkvR+KhADB90YtYz1T7yXEh6CmMhxcX9dIVTykm6qEjj3hKcUEvR+KhADBt0QvYgPzWy1QT9NSVczylqKCPznhKMVEPHfmGpxSlug8nfUQ528MBYLr0YrXuc7Zr46WqiXrqyCueUlTQx6oU/ZhVUL8rp3hKUUEfR+KhADBderF6Pn3x2iRerpqop654SlFRHytS7Kdw1fpiUrsznlKU6vZ5d/fbHg4A06QXqoeSF66N4yWriXrqiqcUFfWxIsWudKNajye1O+MpRUV9BLnKwwFgevQidVnyorVVvGw16uGttKcVudzTigl6WJV7PC071eq8jnAaTylGNXt9Tz18FtQvf2sG9ol2+mPtF6wx4qWrUQ+/THtaFU8rJuphRZ7ztOyC2p3xlGKiHoK86eGTpj6/734f800Adp12+JO9448aL1+Neuh7ruKDeFoxUQ8r8pGnZRfU7oynFKF6d6f1O1L9pCurqL9vtXqt9jlmABW0dv6xU/U6qap/TdLPuhT91V5Qf2U8Lbuodlc8pYiofhQPnxz1dupcegWQQfoCMHKecpkqVP/IC9ya3OepRahe71M7NvG07KLaXfGU7FSr77WDJ3kQU1+vzKFPAJlokx/ypqKN4lLVRD2tiqcVoXqvp/VXxdOyi2p35D88JTvVej+p3ZVvesokqJ+ui+JPqk8AGWmHvyN5AcgSl6sm6mlVPK0I1Xsmrb8qnpaV6gx5zopdpzeoHcbDJ0H9PJn257zrIQB2nXb40d+RvCKuWkfQz7rc7KnZqdagN3UpF3pqNqrx2aTmqrzgaVmpzu1J3c54SnVRb4t4CIB9EL0IZMxlLluF6h/529mafOip2anWrUntdbnJU7NRjSuTmqvyuKdlFdTtSvWzS6mHdf2e66EAdl3wApA7D7p0Faq/+Kxj73hqdqr1hbT2mjzsqdmoxk1JzVUpcjKOoG5XLvaUKlR/3Skxq19BC0Ah2uEfSF4AisTlq1D9K9J+eqTICflVZ+i7qLOc0EHrNn2cpjR/auh7Hdwm93qJbFTjjKRmZzylCtVf+x8VDwWw67TDn5O+AJSKW6gm6mlNfu2p2QW1V8bTQrq/OWg2P2U1J1b4ifKy8rESrpU5rymPKk0vzSlDN7rakeY1jyFa/0g8pTjVvjHtJchZHg5g1wUvACVzutuoIuhnbTw1u6j2mjTvLn83uW3O+a3SnEHqTD8lS1rj1uVZTylKdW9J+ogyi1NNAhiBdvjsn7ddk/vdShWq3/unpEU8NbuoNjlMn8vwLVLj4hNdn7FdiocD2HXa4a9PXwBqxO1UofpXp/30yN2enoXWbzL01JOkI35ai1HNvucfv9FTAOy64AWgStxONVFP6+Kpo9B6f6Pc016fjJpr/VQXEdQP4+EAdl30AlArbqmaqKd18dSNaP55yr+21yNFk+3jaFr7g6RWGA8HsOu0w1+bvgBUTpU3tSyo/n8l/fTJtz19LY1t3h38YmsumVYeUk72t2tjWuOu1pqr8kdPAbDrgheA6nFrVaj+Rn8v9fQjdF/zEZzvtseS2eQ3ykbXzE3W6YyHA9h12uGHns6wSNxeNVFP6+KpB/R180aZx9r3zyDNVXZeUH6kNJ+JbU7d2Py6u/PkHrovWidKc1KK5mQZzaXzmo/HPKj8SnlPicZPNb3e2BTM60rV3+YAKEQ7e+8z81TIHW6ziqCfPml+TTzFz73+u/JD5Qt+eKNp1VgZDx9Mcy9Vmgs39L3kXsk84TaX6PbmNxrR+CPxFAC7LnoBmFLcZhWq3/wEFvY1p/jhZBPVjOLho9GapyvNT8tVTkEa5Em3NmS/esBTAOwy7exfT3b+Kcbd1hH0M8dkPU1gUC+Mh2eh9af2pr9ecfsAdl30AjDB3Od2qwj6qZHm19RLly3U1z9v3b8uuU/KEdU8Eg/PQuv3vWpRrXNFR3nU7QPYZdrZf5bs/JONW65C9Zs3DoV9Zcz3XL6TxvT+G6HygadlEdQL4+FZaP1eF+f38AP6unn/wtPt+0vGbcyGem5+I9Z8VvyzvgnAOtphTmp2+BnlHLdelOqW+hvuceU8l+0tWWNlPCULrf9RWi+Kh2eh9Z9M60Xx8JDub/4e/Mv2+Jxx2clSj/emPSuX+G4AfWhnmdvVY95y69mp1llK87GYqI+x8qay0ec627RG71+PekoWWv/ZtF4UD89C6/e54MSgC7prfIlTazaXJHTF+tRL52P2EAB9acf5ZLojzSFuPxvVODutOXKedqnRaM3mMnVRrSPxlCy0/u1pvSgenoXWfzutF+QCDx9Mcy9Sep2iccN87FLFqfa6Cyu86KEAhgh2prnkLj+EUTXrJnXGTNbLDGr9Id/P8z1tdFr7nKRWGA/PQut/mNZL46Fb01pNnmmvPXKKXDpQdfp837h6EbAJ7TxNop1qFvHDGIXW6/U3vy1zp8tlE9TsStYXzqDekXhoFlG9NB46Kq3bnDnrF+06I+YelxmV1j0zqdOVL3oKgKGCHWpu2foNG1rjqWTNrHHZbFSj738cfu4pWQT1jsRDs4jqpfHQbKKaI+Vel9ia1ur193blJE8BMJR2oOb6qtGONav44QymuVXOF+3y2ajGqWnNrnhKFlG9NB6aRVQvyUsemoXW7/UcbJnbXG4wze3dn6cA2JR2pD5vKplDjvkh9aLxJ5L5pfOwW8kmqBnGw7OI6qXx0Cyiekn+3kOz0PrNm6qiujnyI5ftReObc2hH6xyJpwDYRrRzzTQn/JBW0rjnk3nbpHl36qVe95HW7b1y0FBGUc0oHp6F1l/7GwQPzSKqlyTrZ7m1fp8Tb/xjcNs2WfufOY3p83GpRT7paQA2pR1p2wudN+9mbK42E91XI53nBtZ99yVjt8kLXnZJMG5lPC0b1fhMWrMjF3nK6LT22ufdQ7OI6rXjYdmoxltpzTQe2oxtznA15v50s5deotuHXF2Jv9kCYwh2rkHxMluvM2bc0iHd9sV0zBb5lpcN6f7mZAXRvK6EB+4xBTWjZDyntdZuztIU1TyMh2YR1WvHw7KJaib5nYcu0e1jvlv+dC/brPtact+qXOhpALahnWnbs+Us/c00uL9K3E7TT6/PgPZM7187BnNXxtOyiWoGyXoCg6DeUjwsi6heKx95WDZBzTQrT92p+69Jxm+TIR9TusUtANhWsIMNipc5pNt6nSS+UNae7KBnBp+BSHP6frxikay/stP61yf1wnh4FlG9djwsC62/6ixQ2a/KE9RcioetpbFXpHMzhqsVAWMKdrIhud7LLAnGzTWHv4LbRLDeqjzvadkENY/EQ7OI6rXjYVlo/TfSeq1sfd7qVbT+KUm9NIN/s6A5X0rWGD0uBWAM2ql+n+5kQ+JlQtH4ucQPYWtaa9AZhjwtG9VYe1EKD81C66883aGHZaH1V11wYtBHyYbS+p9L6qXZ+IxNmpvlHN9eHsBYoh1tQN7xMiHdf2cyfg75lNsfTVBjVb7saVlo/a8l9aJkO/ho7ZX1PSwLrf9EWm8RD8lGNVb+/dXDtqJ1zkvX3SJb/WYHQEI71a3JTjY0Z3qpTsGcqeYLbnl0WvsfklqrsvI/MWMIaqY57qGj09orz9HrYVlo/R+k9RbxkGxU48a0ZiujvkNd6/X5T9W6ZP0VO7B3gp1sULzMShrXfJ4wnD+RFHlhCep2xlOyUY111/L9wEOzCOodxkOy0Po3pfUW8ZBsVONbac1WNr4k4Cpa98GkztC87aUAbCvYwYak97sXg7lTyA/cXhGq1+sdwk6WywwuaP111zbNfeALazbxkCy0/lfSes6rHpKNanRel9hDslGNIZ+3jZLttz/AXtBONPj0g0nO9lJraexZydyayX6CiS5BL53xlGyimu14WBZa/6W03iIekoXWPz+t56w8ickYVOP7Sc3DeEhWUd2h8VIAhop2qCHxMr1Fa1RK1kvQraLavU9e7ynZqMZDac12PCwLrX9JWm8RD8lC63f9ZH+ah2SjGt9Lai5ytYdkoxoXJjW3yZVeFkBfwY40JD/2Mr1pzphnydk2W18zd1NBL12pfQWhrO9SDeodxHdnU6NmQ3W+ndZt4ruzUp1tz5OeptpviYDZ0Q7T9b/tvjnZSw0SrFMtbqk41V7799NFPCWbqGYrD3hYFkG9g/jubGrUbKjOLWndJr47q6juGPHyAFaJdp4h8TKDae6r6VoV0+sSfjmo9nNJL13Jeik0rX9DUm8pHpZFVK+J786mRs2G6lyX1lXe8N1ZBXXTHA9u65t7XAZAJNhpBsXLDKa5Y/4taYxkPbvQKkEvUf7Zw7MJah7GQ7LQ+uHfkH13NqrxcemaDdWJrlR1me/ORjUuTWqmecVDm7Enkvv6JvuFH4BZ0s7xqWRnGZprvdRGgvWqxm0Vp9qdnwltx8OzUY3Oywh6SBZaP/zVuu/ORjUeL12zoTpHTr/ou7JSnZV/v/WwQ7rtqnTMgJziZQA0tFM8newkg+JlNhatWTnhNUhLCHqJkvVdrFp/VR9neFgWQb0SB9z0V7tP+a6sVOfI4/VdWaU1k3T+WUX3/S4Z2zdcyg9YCHaQQfEyG4vWnEBudXvFBb2k+aOHZhPUXORrHpJFUK/EATf9yfom35VdUvcR35xVUnMpHtJJYza9GlG1/8QCkxLsHIPiZTYWrTmFuL3iVHvtG8k8NBvV6DohRNbLBWr9IxcT8F1ZJTVP9c3ZJXWLfDQtqdnO4d9u19HY/0zm9oqnA/tJO8HF6U4xMFt/NlRr/DlZczJxi8VFvSS530OzCWoexHdnofWPHOh9V1al6y3UqNuu2Y7v7k1z7k3X6JmLvERI9zdp3kx5m/KU8r4SrROlub7xw0pz2tTeZ74DitBGue3pHM/1UhsL1pxSqnxUSHXX/urOQ7NRjXvSmk18dzal6zVK11tQvTdL113US7LxFamCtfrkbk9v5jcnwPmwdV+uvKdc5bJAeckGOTheZivRuhNL1r9bdgn6WIqHZRXVVXJ/Fnipnm/OSnX+ULLeguotrt7zsm/KSnXOdb00n/aQjWj+4X8cZpY7/BCA/IINcFC8zFaidSeYYn/Xawv6aOclD8tGNd5Jajb5O9+dhdZfumydb85Kdb5Tst6C6l3mutk/f9tQnatdbym+eytap/PqRzPJXYofDZBBssENjpfZmNbo/Mzn1OKWi1Ld8Ne6i3hYNqoRXRw+68UetP5J7Xq+OTvX+9hfFqF6B3X9ZXaqFV30frRL7WmtxfM492T9TyX2kDaqv002sqH5lZfaWLDmpOO2i4r6aCX7mbGCmiUO9MVqLbhe8ZPwF36MR/4D57tGldaYcbjgPsahjenJZOMamsM3PmxC819I1ptDsr87OBL0cRgPyUY1jpxpyHdloxqHF0j3Tdm53n3+spjCjzG9Bm+2j3lp7SMf8Zp5LvdDA4bTBnTkHLIDs/EZjzT3zmStOeVLfhjFqGbn8+UhWZWuqRqnlKq14Hrf9JfFqGax68mq1tJPuL45G9VYeTGMmebrfnhAf8GGNDRnealBNC/6O9Lc4kdTTtDDItl/KlONryQ1z/Nd2Sxq+cvsVOsxpcibl2rR47t98bw28c1Zqc7hbyt2LNn3AeyQYAMaFC8ziOYdOVH8XOOHVFTURxPfnVVS80nfnE2rlm/JS3XOU6q8G70UPb5v+DltUuQyeqrzUavmzsUPE1gt2niGxMv0ovHbntFqkvHDK0Y1w4uWKxd4SDaq0Zz557Cmb85GNRY/jXHGoJHouTy8JKBvym5Rb8fzvh8ucJQ2kG0vyddrh9W4K9J5O5as5xaOqObhSRpaKXJy+HZN35SVa219NjP8hZ7L0/2c/t43Zed6+5Lv+GEDf6UN49pkQxkcLxXS/Ut/K9rx3O6HXUzQQ6kD4OGfBHxTVq51hb/ECPycXucvs3O9vYofOvAX2ii2PYfy0kalr5tfVb3evn/PkvUatSnVa07unvZwve/OqlXPt+SjGs2pD2/wlxhB873zP4vwtrKPuddPAfadNoa5nvt0ytnoXdubUr1nkvqlfupc/Gdtq89h96EapynFrk+7D5rvnf9ZhLeVvY2fBuyzaMMg28dPbzG16pespzpn+J8YgZ7P0U7l2MdiW9nzFPntEyYq2CDISPFTXExS/1HfnJXqPNTU85dAp9a2ue/JfrERTFSwMZAR46e5CNW7qUZt1/NXQKy9bRL+k7qXog2BjBs/1UWo3qut2l/1zVmpzrPKpf4SCLW2S/LXcCH8fRJsAGT8vOenu4h2bd+UnWrd6H8CofZ2SZbyQz9F2HXBN5/kyc/8lBexqOsvs1Otz/ifQGixTZIw/F13HwTfeJIvD/hpz061FufKfdo3AVV5eyQr4qcKuyr6ppOsKfbrI9U6uM6xvwSqau0DpDsn/HRhFwXfcJI/xf7e6XpFT8QBRFrbP/lr3lV+qBzz04Rd1vrGk7IpduWbpp7/CVSTbP/7mObgequfDuyjZIMgZXOxvw1ZqQ5naEJ1yba/y/lAuU9hv8Oy1kZC6uQSfyuAnRZs+3NPcx7648qVyul+mEA3bzikbriwOnZesN3PJa8pzU+sl/uhAJtpbVSkbvwdAXZTsM1PKX9QfqJc5HaB8bU2OFI/J/vbAuycYHsvnRPK3cqn3RJQVmtjJNPISf7WADsl2NZz5/MuDUxDsJGSyvG3Btgp0baeMa+7LDAdwYZKJhB/e4CdEW3nGXOqywLToQ2zeQdetMGSunnY3yJgJwTbeLa4JDAt2jgfSjdWUjW/UfjfOXZOsp3nzPMuCUyLNs6vJBsrqZMn/C0BdpK28d8l23yWuBwwTdFGS4qFjyhgL2hbfynZ9rPE5YBpijZakjW3+KkH9oa2+0eS/SBHrnE5YJqCjZaMn8eVM/2UA3tH2/8drf0hS1wKmK5owyWj5BfKKX6agb2mfeHi1r6RI8ddCpgubagvJxsu2Tx3+2kFkAj2l9HiEsC0aWO9M914Se88pZzlpxLACsm+M2ZecAlg2rSxnpRsvKQ7zyvX+akDMECyL40WLw/MQ7QRk4P8k8JF4oERJPvWaPHywDxoo/0w3Yj3MM1FprlaD5BJsr+NEi8NzIc23KvSDXlH8y/KbcoxP3QAhWi/e9P74Vj5yEsD86SN+FTlcqX53NwTyhtKtLFPLe8rzyrHleuVi/yQAEyA9slHlWjf3TRne2lgP2ijP6Y0B+gblLuVB5TmQP2c8mvlhPO20uwkHzl/VP6kfKAsxjQfUWremPSM8hPlHuUWpfkJ/AKFz7UCM+V9OT1obpq3vSwAAGjTQfLC5KC5TU7zsgAAIBUcODfJW14OAABEgoPn4HgpAADQJTqADgxnlQIAYB0dMLc6d7uXAQAAq+igeXN6EB2Q73oZAACwig6apyUH0d7xEgAAoI/oYNojXJULAIAhgoPpurzmqQAAoK/ggLodnAYAAIbQQbS5Mld4cA1yjacBAIChggNrlHc8HAAAbCI4uB6JhwIAgE1FB9gkXF4TAIBt6YDaXI4zOtA2edDDAADANnRQvTE5yB7GQwAAwBg42AIAUEBwwOWi8gAAjE0H2F+1DrZX+mYAADAmHWSv8cH2Jt8EAABy0MH2Lv8TAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQG2f+MT/AxeZknFjILX/AAAAAElFTkSuQmCC"

    function Get-LogoSource {
        try {
            $bytes = [Convert]::FromBase64String($logoBase64)
            $ms = [System.IO.MemoryStream]::new($bytes)
            $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
            $bi.BeginInit()
            $bi.StreamSource = $ms
            $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bi.EndInit()
            $bi.Freeze()
            return $bi
        } catch {
            return $null
        }
    }

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gricko SS Tool" Height="640" Width="600"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ResizeMode="NoResize" FontFamily="Segoe UI, Tahoma, Helvetica, Arial"
        Topmost="True" ShowInTaskbar="True">

    <Window.Resources>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="6"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Track Name="PART_Track" IsDirectionReversed="True">
                            <Track.Thumb>
                                <Thumb>
                                    <Thumb.Template>
                                        <ControlTemplate TargetType="Thumb">
                                            <Border Background="#2A3854" CornerRadius="3"/>
                                        </ControlTemplate>
                                    </Thumb.Template>
                                </Thumb>
                            </Track.Thumb>
                        </Track>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#0F1626"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="BorderBrush" Value="#253552"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#0F1626"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#1E293B"/>
                    <Setter Property="Foreground" Value="#00F0FF"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#2A1B4E"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Border Name="RootBorder" Background="#07090E" CornerRadius="16" BorderBrush="#1C273E" BorderThickness="1.5">
        <Border.Effect>
            <DropShadowEffect BlurRadius="45" Color="#00F0FF" Opacity="0.22" ShadowDepth="4"/>
        </Border.Effect>

        <Grid Margin="20,14,20,16">
            <Grid.RowDefinitions>
                <RowDefinition Height="36"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="20"/>
            </Grid.RowDefinitions>

            <!-- TITLE BAR -->
            <Grid Name="TitleBarGrid" Grid.Row="0" Background="Transparent">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Background="#0E1726" BorderBrush="#00F0FF" BorderThickness="1" CornerRadius="5" Width="20" Height="20" Margin="0,0,8,0" VerticalAlignment="Center">
                        <TextBlock Text="&#x2726;" Foreground="#00F0FF" FontSize="10" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="GRICKO" Foreground="#FFFFFF" FontWeight="ExtraBold" FontSize="13.5" VerticalAlignment="Center"/>
                    <TextBlock Text=" FORENSIC" Foreground="#00F0FF" FontWeight="Bold" FontSize="13.5" VerticalAlignment="Center"/>
                    <Border Background="#1A102E" BorderBrush="#581C87" BorderThickness="1" CornerRadius="4" Padding="6,1.5" Margin="8,0,0,0" VerticalAlignment="Center">
                        <TextBlock Text="v2.4 HYPER-INVARIANT" Foreground="#C084FC" FontSize="9" FontWeight="Bold"/>
                    </Border>
                </StackPanel>

                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Border Background="#062A1F" BorderBrush="#059669" BorderThickness="1" CornerRadius="10" Padding="8,2" Margin="0,0,12,0" VerticalAlignment="Center">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="&#x25CF;" Foreground="#10B981" FontSize="9" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <TextBlock Text="ENGINE ARMED" Foreground="#34D399" FontSize="9.5" FontWeight="Bold" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Border>

                    <Button Name="BtnMin" Content="-" Width="28" Height="24" Background="#0C1220" Foreground="#94A3B8" BorderBrush="#1C273E" BorderThickness="1" FontSize="11" Cursor="Hand" FontWeight="Bold">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnClose" Content="X" Width="28" Height="24" Background="#0C1220" Foreground="#94A3B8" BorderBrush="#1C273E" BorderThickness="1" FontSize="11" Cursor="Hand" FontWeight="Bold" Margin="4,0,0,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- MAIN CONTENT AREA -->
            <Grid Grid.Row="1" Margin="0,8,0,4">

                <!-- VIEW 1: HOME (CYBER-OBSIDIAN HERO STYLE) -->
                <StackPanel Name="HomeView" Visibility="Visible" HorizontalAlignment="Center" VerticalAlignment="Center" Width="440">
                    <Border Width="110" Height="110" Background="#0B1220" BorderBrush="#1E2E4A" BorderThickness="1.5" CornerRadius="55" HorizontalAlignment="Center" Margin="0,0,0,14">
                        <Border.Effect>
                            <DropShadowEffect BlurRadius="30" Color="#00F0FF" Opacity="0.30" ShadowDepth="0"/>
                        </Border.Effect>
                        <Image Name="LogoImgHome" Width="85" Height="85" HorizontalAlignment="Center" VerticalAlignment="Center" RenderOptions.BitmapScalingMode="HighQuality"/>
                    </Border>

                    <TextBlock Text="GRICKO SCREENSHARE" Foreground="#FFFFFF" FontSize="22" FontWeight="ExtraBold" HorizontalAlignment="Center" Margin="0,0,0,3">
                        <TextBlock.Effect>
                            <DropShadowEffect BlurRadius="15" Color="#00F0FF" Opacity="0.35" ShadowDepth="0"/>
                        </TextBlock.Effect>
                    </TextBlock>
                    <TextBlock Text="Next-Gen Automated Minecraft Forensic Engine" Foreground="#94A3B8" FontSize="12" HorizontalAlignment="Center" Margin="0,0,0,14"/>

                    <!-- Feature Badges -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,24">
                        <Border Background="#0C1628" BorderBrush="#1D3050" BorderThickness="1" CornerRadius="12" Padding="9,3" Margin="0,0,6,0">
                            <TextBlock Text="[+] Multi-Instance" Foreground="#38BDF8" FontSize="10" FontWeight="SemiBold"/>
                        </Border>
                        <Border Background="#1A112C" BorderBrush="#3B2260" BorderThickness="1" CornerRadius="12" Padding="9,3" Margin="0,0,6,0">
                            <TextBlock Text="[*] Invariant Bytecode V3" Foreground="#C084FC" FontSize="10" FontWeight="SemiBold"/>
                        </Border>
                        <Border Background="#06221A" BorderBrush="#0D4435" BorderThickness="1" CornerRadius="12" Padding="9,3">
                            <TextBlock Text="[#] Anti-Evasion Lock" Foreground="#34D399" FontSize="10" FontWeight="SemiBold"/>
                        </Border>
                    </StackPanel>

                    <!-- Ultra-Premium Glowing Gradient SCAN Button -->
                    <Button Name="BtnScan" Width="260" Height="48" Content="START FORENSIC SCAN" FontSize="13.5" FontWeight="Bold" Foreground="#FFFFFF" Cursor="Hand">
                        <Button.Effect>
                            <DropShadowEffect BlurRadius="28" Color="#00F0FF" Opacity="0.75" ShadowDepth="0"/>
                        </Button.Effect>
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border Name="BtnBorder" CornerRadius="24">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#00F0FF" Offset="0.0"/>
                                            <GradientStop Color="#3B82F6" Offset="0.5"/>
                                            <GradientStop Color="#8B5CF6" Offset="1.0"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="BtnBorder" Property="Background">
                                            <Setter.Value>
                                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                    <GradientStop Color="#38BDF8" Offset="0.0"/>
                                                    <GradientStop Color="#60A5FA" Offset="0.5"/>
                                                    <GradientStop Color="#A855F7" Offset="1.0"/>
                                                </LinearGradientBrush>
                                            </Setter.Value>
                                        </Setter>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>

                    <TextBlock Text="Deep Memory, BAM &amp; Prefetch Kernels, All Instances &amp; Jar Invariants" Foreground="#64748B" FontSize="10.5" HorizontalAlignment="Center" Margin="0,14,0,0"/>
                </StackPanel>

                <!-- VIEW 2: PROGRESS SCAN VIEW (CYBER TELEMETRY) -->
                <StackPanel Name="ProgressView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="480">
                    <Border Width="90" Height="90" Background="#0B1220" BorderBrush="#1E2E4A" BorderThickness="1.5" CornerRadius="45" HorizontalAlignment="Center" Margin="0,0,0,12">
                        <Border.Effect>
                            <DropShadowEffect BlurRadius="25" Color="#00F0FF" Opacity="0.35" ShadowDepth="0"/>
                        </Border.Effect>
                        <Image Name="LogoImgProgress" Width="68" Height="68" HorizontalAlignment="Center" VerticalAlignment="Center" RenderOptions.BitmapScalingMode="HighQuality"/>
                    </Border>

                    <TextBlock Text="DEEP SCANNING SYSTEM" Foreground="#FFFFFF" FontSize="18" FontWeight="ExtraBold" HorizontalAlignment="Center" Margin="0,0,0,2"/>
                    <TextBlock Text="Decompiling bytecode &amp; verifying execution history across all instances" Foreground="#94A3B8" FontSize="11.5" HorizontalAlignment="Center" Margin="0,0,0,16"/>

                    <TextBlock Name="TxtProgressPercent" Text="0%" Foreground="#00F0FF" FontSize="28" FontWeight="ExtraBold" HorizontalAlignment="Center" Margin="0,0,0,6">
                        <TextBlock.Effect>
                            <DropShadowEffect BlurRadius="12" Color="#00F0FF" Opacity="0.5" ShadowDepth="0"/>
                        </TextBlock.Effect>
                    </TextBlock>

                    <Border CornerRadius="8" Height="14" Background="#111726" BorderBrush="#1E293B" BorderThickness="1" Margin="0,0,0,14" ClipToBounds="True">
                        <ProgressBar Name="ScanProgress" Height="14" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0">
                            <ProgressBar.Foreground>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#00F0FF" Offset="0.0"/>
                                    <GradientStop Color="#3B82F6" Offset="0.6"/>
                                    <GradientStop Color="#8B5CF6" Offset="1.0"/>
                                </LinearGradientBrush>
                            </ProgressBar.Foreground>
                        </ProgressBar>
                    </Border>

                    <!-- Telemetry Card -->
                    <Border Background="#0B101E" BorderBrush="#1A2740" BorderThickness="1" CornerRadius="8" Padding="14,8">
                        <TextBlock Name="TxtProgressStatus" Text="Initializing deep PC inspection... - 0%" Foreground="#93C5FD" FontSize="11.5" FontWeight="SemiBold" HorizontalAlignment="Center"/>
                    </Border>
                </StackPanel>

                <!-- VIEW 3: RESULTS SUMMARY (100x BETTER VERDICT + CLIENT INFO) -->
                <StackPanel Name="ResultsView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="520">
                    <Image Name="LogoImgResults" Width="100" Height="50" HorizontalAlignment="Center" Margin="0,0,0,8" RenderOptions.BitmapScalingMode="HighQuality"/>
                    
                    <TextBlock Name="TxtResultTitle" Text="Scan Complete" Foreground="#FFFFFF" FontSize="20" FontWeight="ExtraBold" HorizontalAlignment="Center" Margin="0,0,0,2"/>
                    <TextBlock Name="TxtResultSubtitle" Text="System &amp; client inspection finished" Foreground="#34D399" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,12"/>

                    <!-- Target Client & Instance Spec Card -->
                    <Border Background="#0A101D" CornerRadius="10" BorderBrush="#1C2B44" BorderThickness="1.5" Padding="16,12" Margin="0,0,0,10">
                        <StackPanel>
                            <DockPanel Margin="0,0,0,6">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="TARGET CLIENT &amp; INSTANCE" Foreground="#00F0FF" FontSize="11" FontWeight="ExtraBold"/>
                                </StackPanel>
                                <TextBlock Name="TxtResultTime" Text="N/A" Foreground="#38BDF8" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                            </DockPanel>

                            <!-- Client / Instance Selector Dropdown -->
                            <ComboBox Name="CmbResultInstance" Margin="0,2,0,8" Cursor="Hand"/>

                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0">
                                    <TextBlock Name="TxtResultClient" Text="Client   : Detecting..." Foreground="#E2E8F0" FontSize="11.5" FontWeight="SemiBold" Margin="0,1.5"/>
                                    <TextBlock Name="TxtResultProfile" Text="Profile  : Standard" Foreground="#94A3B8" FontSize="11" Margin="0,1.5"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1">
                                    <TextBlock Name="TxtResultServer" Text="Server   : None" Foreground="#38BDF8" FontSize="11" Margin="0,1.5"/>
                                    <TextBlock Text="Integrity: Bytecode Verified" Foreground="#34D399" FontSize="11" Margin="0,1.5"/>
                                </StackPanel>
                            </Grid>
                        </StackPanel>
                    </Border>

                    <!-- Cheat & Mod Detection Result Box -->
                    <Border Name="DetectionBox" Background="#0A101D" CornerRadius="10" BorderBrush="#1C2B44" BorderThickness="1.5" Padding="16,10" Margin="0,0,0,14">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="TxtDetectionsBadge" Text="[OK] No Cheats or Suspicious Clients Detected" Foreground="#34D399" FontSize="12.5" FontWeight="ExtraBold" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtCheatList" Text="" Foreground="#F87171" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,4,0,0" Visibility="Collapsed" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Border>

                    <!-- Action Buttons -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button Name="BtnDetails" Content="FORENSIC DETAILS" Width="140" Height="36" FontSize="11.5" FontWeight="Bold" Foreground="#00F0FF" Background="#0C182A" BorderBrush="#00F0FF" BorderThickness="1" Cursor="Hand" Margin="0,0,8,0">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="18"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                        <Button Name="BtnMods" Content="ALL MODS" Width="140" Height="36" FontSize="11.5" FontWeight="Bold" Foreground="#FFFFFF" Background="#261642" BorderBrush="#A855F7" BorderThickness="1" Cursor="Hand" Margin="0,0,8,0">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="18"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                        <Button Name="BtnRescan" Content="RE-SCAN" Width="100" Height="36" FontSize="11.5" FontWeight="Bold" Foreground="#94A3B8" Background="#0B101D" BorderBrush="#1C273E" BorderThickness="1" Cursor="Hand">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="18"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                    </StackPanel>
                </StackPanel>

                <!-- VIEW 4: CLEAN DETAILS VIEW -->
                <Grid Name="DetailsView" Visibility="Collapsed" Height="470" Margin="2,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,8">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="FORENSIC INSPECTION DETAILS" Foreground="#FFFFFF" FontSize="14" FontWeight="ExtraBold" VerticalAlignment="Center"/>
                        </StackPanel>
                        <Button Name="BtnBackFromDetails" Content="&lt;- Back" Background="Transparent" Foreground="#00F0FF" BorderThickness="0" FontSize="12.5" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Right"/>
                    </DockPanel>

                    <!-- Client & Instance Chooser in Details -->
                    <Border Grid.Row="1" Background="#0C1322" CornerRadius="8" BorderBrush="#1F2D48" BorderThickness="1" Padding="10,5" Margin="0,0,0,8">
                        <DockPanel>
                            <TextBlock Text="TARGET INSTANCE:" Foreground="#00F0FF" FontSize="11" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <ComboBox Name="CmbDetailsInstance" Cursor="Hand"/>
                        </DockPanel>
                    </Border>

                    <Border Grid.Row="2" Background="#06080E" CornerRadius="10" BorderBrush="#172236" BorderThickness="1" Padding="12">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel Name="DetailsContentPanel">
                                <!-- Populated dynamically based on selected client/instance -->
                            </StackPanel>
                        </ScrollViewer>
                    </Border>

                    <DockPanel Grid.Row="3" Margin="0,8,0,0">
                        <TextBlock Name="TxtSummaryStats" Text="Clean Forensics" Foreground="#64748B" FontSize="11.5" VerticalAlignment="Center"/>
                        <Button Name="BtnExportJson" Content="Export Full JSON" Height="28" Padding="14,0" Background="#1D1233" Foreground="#C084FC" BorderBrush="#581C87" BorderThickness="1" FontSize="11.5" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Right">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="6"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                    </DockPanel>
                </Grid>

                <!-- VIEW 5: ALL INSTALLED MODS BROWSER -->
                <Grid Name="ModsView" Visibility="Collapsed" Height="470" Margin="2,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,8">
                        <StackPanel>
                            <TextBlock Name="TxtModsTitle" Text="INSTALLED MODS" Foreground="#FFFFFF" FontSize="14" FontWeight="ExtraBold"/>
                            <TextBlock Name="TxtModsSubtitle" Text="Last Played Instance" Foreground="#C084FC" FontSize="11.5"/>
                        </StackPanel>
                        <Button Name="BtnBackFromMods" Content="&lt;- Back" Background="Transparent" Foreground="#00F0FF" BorderThickness="0" FontSize="12.5" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </DockPanel>

                    <!-- Client & Instance Switcher in Mods View -->
                    <Border Grid.Row="1" Background="#0C1322" CornerRadius="8" BorderBrush="#1F2D48" BorderThickness="1" Padding="10,5" Margin="0,0,0,8">
                        <DockPanel>
                            <TextBlock Text="INSTANCE:" Foreground="#00F0FF" FontSize="11" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <ComboBox Name="CmbModsInstance" Cursor="Hand"/>
                        </DockPanel>
                    </Border>

                    <!-- Filter / Search Box -->
                    <Border Grid.Row="2" Background="#0C1322" CornerRadius="8" BorderBrush="#253552" BorderThickness="1" Padding="12,6" Margin="0,0,0,8">
                        <DockPanel>
                            <TextBlock Text="Filter Mods:" Foreground="#64748B" FontSize="11.5" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <TextBox Name="TxtModSearch" Background="Transparent" Foreground="#F8FAFC" BorderThickness="0" FontSize="12" VerticalAlignment="Center"/>
                        </DockPanel>
                    </Border>

                    <!-- Mods List ScrollViewer -->
                    <Border Grid.Row="3" Background="#06080E" CornerRadius="10" BorderBrush="#172236" BorderThickness="1" Padding="10">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel Name="ModsListPanel">
                                <!-- Populated dynamically with clean mod cards -->
                            </StackPanel>
                        </ScrollViewer>
                    </Border>

                    <DockPanel Grid.Row="4" Margin="0,8,0,0">
                        <TextBlock Name="TxtModsSummaryStats" Text="0 Mods Installed" Foreground="#64748B" FontSize="11.5" VerticalAlignment="Center"/>
                        <TextBlock Name="TxtModsFlaggedCount" Text="" Foreground="#EF4444" FontSize="11.5" FontWeight="ExtraBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </DockPanel>
                </Grid>

            </Grid>

            <!-- FOOTER WATERMARK -->
            <Grid Grid.Row="2">
                <TextBlock Text="powered by Gricko SS Tool | Anti-Evasion Invariant Engine V3" Foreground="#475569" FontSize="10" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,4,2"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $xml = [xml]$xaml
    $reader = [System.Xml.XmlNodeReader]::new($xml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # UI Element Handles
    $rootBorder        = $window.FindName("RootBorder")
    $titleBarGrid      = $window.FindName("TitleBarGrid")
    $btnMin            = $window.FindName("BtnMin")
    $btnClose          = $window.FindName("BtnClose")

    $homeView          = $window.FindName("HomeView")
    $progressView      = $window.FindName("ProgressView")
    $resultsView       = $window.FindName("ResultsView")
    $detailsView       = $window.FindName("DetailsView")
    $modsView          = $window.FindName("ModsView")

    $logoImgHome       = $window.FindName("LogoImgHome")
    $logoImgProgress   = $window.FindName("LogoImgProgress")
    $logoImgResults    = $window.FindName("LogoImgResults")

    $btnScan           = $window.FindName("BtnScan")
    $btnRescan         = $window.FindName("BtnRescan")
    $btnDetails        = $window.FindName("BtnDetails")
    $btnMods           = $window.FindName("BtnMods")
    $btnBackFromDetails= $window.FindName("BtnBackFromDetails")
    $btnBackFromMods   = $window.FindName("BtnBackFromMods")
    $btnExportJson     = $window.FindName("BtnExportJson")

    $scanProgress        = $window.FindName("ScanProgress")
    $txtProgressPercent  = $window.FindName("TxtProgressPercent")
    $txtProgressStatus   = $window.FindName("TxtProgressStatus")

    $txtResultTitle    = $window.FindName("TxtResultTitle")
    $txtResultSubtitle = $window.FindName("TxtResultSubtitle")
    $txtResultTime     = $window.FindName("TxtResultTime")
    $txtResultClient   = $window.FindName("TxtResultClient")
    $txtResultProfile  = $window.FindName("TxtResultProfile")
    $txtResultServer   = $window.FindName("TxtResultServer")

    $cmbResultInstance = $window.FindName("CmbResultInstance")
    $cmbDetailsInstance= $window.FindName("CmbDetailsInstance")
    $cmbModsInstance   = $window.FindName("CmbModsInstance")

    $detectionBox      = $window.FindName("DetectionBox")
    $txtDetectionsBadge= $window.FindName("TxtDetectionsBadge")
    $txtCheatList      = $window.FindName("TxtCheatList")

    $detailsContentPanel = $window.FindName("DetailsContentPanel")
    $txtSummaryStats   = $window.FindName("TxtSummaryStats")

    $txtModsTitle      = $window.FindName("TxtModsTitle")
    $txtModsSubtitle   = $window.FindName("TxtModsSubtitle")
    $txtModSearch      = $window.FindName("TxtModSearch")
    $modsListPanel     = $window.FindName("ModsListPanel")
    $txtModsSummaryStats = $window.FindName("TxtModsSummaryStats")
    $txtModsFlaggedCount = $window.FindName("TxtModsFlaggedCount")

    # Set Transparent Logo on Image Controls
    $logoSrc = Get-LogoSource
    if ($logoSrc) {
        $logoImgHome.Source = $logoSrc
        $logoImgProgress.Source = $logoSrc
        $logoImgResults.Source = $logoSrc
    }

    # Free Window Dragging
    $dragAction = {
        param($sender, $e)
        if ($e.LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            $window.DragMove()
        }
    }
    $window.Add_MouseLeftButtonDown($dragAction)
    $rootBorder.Add_MouseLeftButtonDown($dragAction)
    $titleBarGrid.Add_MouseLeftButtonDown($dragAction)

    $script:isScanning = $false

    # Window Control Actions
    $btnMin.Add_Click({
        if (-not $script:isScanning) {
            $window.WindowState = [System.Windows.WindowState]::Minimized
        }
    })
    $btnClose.Add_Click({
        if (-not $script:isScanning) {
            $window.Close()
        }
    })

    # Screen Lock / Topmost Retention (prevent tabbing out or backgrounding during active scan)
    $window.Add_StateChanged({
        if ($window.WindowState -eq [System.Windows.WindowState]::Minimized -and $script:isScanning) {
            $window.WindowState = [System.Windows.WindowState]::Normal
            $window.Topmost = $true
            $window.Activate()
        }
    })

    $window.Add_Deactivated({
        if ($script:isScanning) {
            $window.Topmost = $true
            $window.Activate()
        }
    })

    $window.Add_Closing({
        param($sender, $e)
        if ($script:isScanning) {
            $e.Cancel = $true
        }
    })

    # Navigation Actions
    $btnDetails.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnMods.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $modsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnBackFromDetails.Add_Click({
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnBackFromMods.Add_Click({
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnRescan.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
        $homeView.Visibility = [System.Windows.Visibility]::Visible
    })

    function Pump-WpfEvents {
        if ($script:isScanning -and $window) {
            if (-not $window.Topmost) { $window.Topmost = $true }
        }
        $frame = [System.Windows.Threading.DispatcherFrame]::new()
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [Action[object]]{ param($f) $f.Continue = $false },
            $frame
        ) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }

    function Add-CleanSectionHeader {
        param([string]$Title)
        $tb = [System.Windows.Controls.TextBlock]::new()
        $tb.Text = $Title.ToUpper()
        $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#818CF8")
        $tb.FontWeight = [System.Windows.FontWeights]::Bold
        $tb.FontSize = 11.5
        $tb.Margin = [System.Windows.Thickness]::new(0, 10, 0, 4)
        $detailsContentPanel.Children.Add($tb) | Out-Null
    }

    function Add-CleanRow {
        param(
            [string]$Label,
            [string]$Value,
            [string]$Color = "#E2E8F0"
        )
        $sp = [System.Windows.Controls.DockPanel]::new()
        $sp.Margin = [System.Windows.Thickness]::new(4, 2, 0, 2)

        $tbLbl = [System.Windows.Controls.TextBlock]::new()
        $tbLbl.Text = $Label
        $tbLbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
        $tbLbl.FontWeight = [System.Windows.FontWeights]::Bold
        $tbLbl.Width = 95
        $tbLbl.FontSize = 11.5
        [System.Windows.Controls.DockPanel]::SetDock($tbLbl, [System.Windows.Controls.Dock]::Left)
        $sp.Children.Add($tbLbl) | Out-Null

        $tbVal = [System.Windows.Controls.TextBlock]::new()
        $tbVal.Text = $Value
        $tbVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
        $tbVal.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $tbVal.FontSize = 11.5
        $sp.Children.Add($tbVal) | Out-Null

        $detailsContentPanel.Children.Add($sp) | Out-Null
    }

    function New-CyberChip {
        param([string]$Text, [string]$BgColor, [string]$FgColor, [string]$BorderColor = $BgColor)
        $b = [System.Windows.Controls.Border]::new()
        $b.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($BgColor)
        $b.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($BorderColor)
        $b.BorderThickness = [System.Windows.Thickness]::new(1)
        $b.Padding = [System.Windows.Thickness]::new(6, 1.5, 6, 1.5)
        $b.Margin = [System.Windows.Thickness]::new(0, 2, 5, 2)

        $tb = [System.Windows.Controls.TextBlock]::new()
        $tb.Text = $Text
        $tb.FontSize = 9.5
        $tb.FontWeight = [System.Windows.FontWeights]::Bold
        $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($FgColor)
        $b.Child = $tb
        return $b
    }

    # Populate Mods View with Clean Cyber Cards
    function Render-ModsList {
        param([string]$Filter = "")
        $modsListPanel.Children.Clear()

        $mods = $Global:ReportData.ActiveInstanceMods
        if (-not $mods -or $mods.Count -eq 0) {
            $tbEmpty = [System.Windows.Controls.TextBlock]::new()
            $tbEmpty.Text = "No mods found for this instance."
            $tbEmpty.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $tbEmpty.FontSize = 11.5
            $tbEmpty.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            $tbEmpty.Margin = [System.Windows.Thickness]::new(0, 30, 0, 0)
            $modsListPanel.Children.Add($tbEmpty) | Out-Null
            return
        }

        $filteredMods = if ($Filter) {
            $mods | Where-Object { $_.Name -like "*$Filter*" -or $_.FileName -like "*$Filter*" -or $_.Reason -like "*$Filter*" }
        } else {
            $mods
        }

        # Sort: Known cheats first, then AI-flagged by risk score, then low-risk, then clean alphabetical
        $sortedMods = $filteredMods | Sort-Object -Property @{
            Expression = {
                if ($_.IsFlagged -and $_.Category -notlike "*HEURISTIC*") { 3 }
                elseif ($_.Category -like "*HEURISTIC*") { 2 }
                elseif ($_.Category -like "*LOW RISK*") { 1 }
                else { 0 }
            }; Descending = $true
        }, @{ Expression = { if ($_.AIRiskScore) { $_.AIRiskScore } else { 0 } }; Descending = $true },
           @{ Expression = { $_.Name }; Descending = $false }

        foreach ($mod in $sortedMods) {
            $card = [System.Windows.Controls.Border]::new()
            $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
            $card.Padding = [System.Windows.Thickness]::new(12, 10, 12, 10)
            $card.Margin = [System.Windows.Thickness]::new(0, 0, 0, 7)

            $cardStack = [System.Windows.Controls.StackPanel]::new()
            $headerDock = [System.Windows.Controls.DockPanel]::new()

            $tbName = [System.Windows.Controls.TextBlock]::new()
            $tbName.Text = $mod.FileName
            $tbName.FontSize = 12
            $tbName.FontWeight = [System.Windows.FontWeights]::Bold
            $tbName.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

            $badge = [System.Windows.Controls.Border]::new()
            $badge.CornerRadius = [System.Windows.CornerRadius]::new(5)
            $badge.Padding = [System.Windows.Thickness]::new(8, 2, 8, 2)
            [System.Windows.Controls.DockPanel]::SetDock($badge, [System.Windows.Controls.Dock]::Right)

            $tbBadge = [System.Windows.Controls.TextBlock]::new()
            $tbBadge.FontSize = 9.5
            $tbBadge.FontWeight = [System.Windows.FontWeights]::ExtraBold

            $isAiHeuristic  = ($mod.Category -like "*HEURISTIC*")
            $isLowRisk      = ($mod.Category -like "*LOW RISK*")

            if ($mod.IsFlagged -and -not $isAiHeuristic) {
                # Confirmed cheat / invariant violation - Red Cyber Glow
                $card.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#150A0E")
                $card.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#991B1B")
                $card.BorderThickness = [System.Windows.Thickness]::new(1.5)
                $badge.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#450A0A")
                $badge.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DC2626")
                $badge.BorderThickness= [System.Windows.Thickness]::new(1)
                $tbBadge.Text         = "CHEAT DETECTED"
                $tbBadge.Foreground   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FCA5A5")
                $tbName.Foreground    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            } elseif ($isAiHeuristic) {
                # AI heuristic risk - Amber Cyber
                $card.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#181008")
                $card.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D97706")
                $card.BorderThickness = [System.Windows.Thickness]::new(1.5)
                $badge.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
                $badge.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
                $badge.BorderThickness= [System.Windows.Thickness]::new(1)
                $riskScore = if ($mod.AIRiskScore) { " ($($mod.AIRiskScore)/99)" } else { "" }
                $tbBadge.Text         = "AI RISK$riskScore"
                $tbBadge.Foreground   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FDE68A")
                $tbName.Foreground    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            } elseif ($isLowRisk) {
                # Low risk / review - Yellow
                $card.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#121105")
                $card.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#854D0E")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $badge.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B2F04")
                $badge.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EAB308")
                $badge.BorderThickness= [System.Windows.Thickness]::new(1)
                $riskScore = if ($mod.AIRiskScore) { " ($($mod.AIRiskScore)/99)" } else { "" }
                $tbBadge.Text         = "REVIEW$riskScore"
                $tbBadge.Foreground   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FEF08A")
                $tbName.Foreground    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EAB308")
            } else {
                # Clean - Emerald / Obsidian Navy
                $card.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0A0F1D")
                $card.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#162238")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $badge.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#062E22")
                $badge.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
                $badge.BorderThickness= [System.Windows.Thickness]::new(1)
                $tbBadge.Text         = "VERIFIED CLEAN"
                $tbBadge.Foreground   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                $tbName.Foreground    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9")
            }

            $badge.Child = $tbBadge
            $headerDock.Children.Add($badge) | Out-Null
            $headerDock.Children.Add($tbName) | Out-Null
            $cardStack.Children.Add($headerDock) | Out-Null

            # Cyber Capability & Invariant Chips
            $chipPanel = [System.Windows.Controls.WrapPanel]::new()
            $chipPanel.Margin = [System.Windows.Thickness]::new(0, 5, 0, 3)

            if ($mod.Invariants -and $mod.Invariants.Count -gt 0) {
                foreach ($inv in $mod.Invariants) {
                    if ($inv -match "Trig") {
                        $chipPanel.Children.Add((New-CyberChip "[AIMBOT TRIG]" "#5A0A0A" "#FCA5A5" "#DC2626")) | Out-Null
                    } elseif ($inv -match "Shield") {
                        $chipPanel.Children.Add((New-CyberChip "[AUTO SHIELD-BREAK]" "#6B082C" "#FBCFE8" "#DB2777")) | Out-Null
                    } elseif ($inv -match "Anchor|Crystal") {
                        $chipPanel.Children.Add((New-CyberChip "[ANCHOR/CRYSTAL MACRO]" "#58125C" "#F5D0FE" "#C026D3")) | Out-Null
                    } elseif ($inv -match "StreamProof|Capture") {
                        $chipPanel.Children.Add((New-CyberChip "[STREAMPROOF EVASION]" "#3B0764" "#E9D5FF" "#9333EA")) | Out-Null
                    } elseif ($inv -match "Web Server") {
                        $chipPanel.Children.Add((New-CyberChip "[EMBEDDED WEB SERVER]" "#172554" "#BFDBFE" "#2563EB")) | Out-Null
                    } elseif ($inv -match "HWID") {
                        $chipPanel.Children.Add((New-CyberChip "[HWID ANTI-LEAK DRM]" "#0F172A" "#CBD5E1" "#475569")) | Out-Null
                    } elseif ($inv -match "Mace") {
                        $chipPanel.Children.Add((New-CyberChip "[MACE WEAPON ASSIST]" "#451A03" "#FDE68A" "#D97706")) | Out-Null
                    }
                }
            }

            if ($mod.Modules -and $mod.Modules.Count -gt 0) {
                foreach ($m in ($mod.Modules | Select-Object -First 4)) {
                    $chipPanel.Children.Add((New-CyberChip "[$m]" "#1E1B4B" "#C7D2FE" "#4338CA")) | Out-Null
                }
            }

            if ($chipPanel.Children.Count -gt 0) {
                $cardStack.Children.Add($chipPanel) | Out-Null
            }

            if ($mod.IsFlagged -or $isAiHeuristic -or $isLowRisk) {
                $tbReason = [System.Windows.Controls.TextBlock]::new()
                $prefix = if ($mod.IsFlagged -and -not $isAiHeuristic) { "[!] " } elseif ($isAiHeuristic) { "[AI] " } else { "[?] " }
                $tbReason.Text = $prefix + $mod.Reason
                $reasonColor = if ($mod.IsFlagged -and -not $isAiHeuristic) { "#FCA5A5" } elseif ($isAiHeuristic) { "#FDE68A" } else { "#FEF08A" }
                $tbReason.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($reasonColor)
                $tbReason.FontSize = 11
                $tbReason.FontWeight = [System.Windows.FontWeights]::SemiBold
                $tbReason.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $tbReason.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
                $cardStack.Children.Add($tbReason) | Out-Null

                if ($mod.AIDetails -and $mod.AIDetails.Length -gt 0) {
                    $tbAI = [System.Windows.Controls.TextBlock]::new()
                    $tbAI.Text = "Deep Forensics: " + $mod.AIDetails
                    $tbAI.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
                    $tbAI.FontSize = 10
                    $tbAI.TextWrapping = [System.Windows.TextWrapping]::Wrap
                    $tbAI.Margin = [System.Windows.Thickness]::new(0, 1, 0, 2)
                    $cardStack.Children.Add($tbAI) | Out-Null
                }
            }

            $tbMeta = [System.Windows.Controls.TextBlock]::new()
            $tbMeta.Text = "Size: " + $mod.SizeKB + " KB  |  Modified: " + $mod.LastWriteTime
            $tbMeta.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#475569")
            $tbMeta.FontSize = 10
            $tbMeta.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
            $cardStack.Children.Add($tbMeta) | Out-Null

            $card.Child = $cardStack
            $modsListPanel.Children.Add($card) | Out-Null
        }
    }

    # Live Search on Mod Box
    $txtModSearch.Add_TextChanged({
        Render-ModsList -Filter $txtModSearch.Text.Trim()
    })

    # Render Forensic Details for Chosen Instance
    $script:cachedActualCheats = @()

    function Render-DetailsForInstance {
        param([PSCustomObject]$inst)

        $detailsContentPanel.Children.Clear()
        if (-not $inst) { return }

        Add-CleanSectionHeader "CHOSEN MINECRAFT INSTANCE & SESSION"
        Add-CleanRow "Client"   $inst.Launcher "#38BDF8"
        Add-CleanRow "Profile"  $inst.Profile "#E2E8F0"
        if ($inst.Version) { Add-CleanRow "Version"  $inst.Version "#E2E8F0" }
        Add-CleanRow "Played"   $inst.LastPlayedTime "#34D399"
        Add-CleanRow "Path"     $inst.Path "#94A3B8"
        if ($inst.ConnectedServers -and $inst.ConnectedServers.Count -gt 0) {
            Add-CleanRow "Server"   ($inst.ConnectedServers -join ", ") "#38BDF8"
        } else {
            Add-CleanRow "Server"   "Singleplayer / Unrecorded" "#64748B"
        }

        if ($inst.IsLogWiped) {
            Add-CleanRow "Log File" "LOG WAS WIPED / 0 BYTES (ALERT!)" "#EF4444"
        } elseif ($inst.SuspiciousLog -and $inst.SuspiciousLog.Count -gt 0) {
            Add-CleanRow "Log Hits" "$($inst.SuspiciousLog.Count) suspicious lines identified" "#FBBF24"
        } else {
            Add-CleanRow "Log Status" "Normal session log integrity" "#34D399"
        }

        Add-CleanSectionHeader "INSTANCE MODS ($($inst.TotalModsCount) TOTAL)"
        Add-CleanRow "Installed" "$($inst.TotalModsCount) mod jar(s) in profile" "#38BDF8"
        if ($inst.FlaggedModsCount -gt 0) {
            Add-CleanRow "Suspicious" "$($inst.FlaggedModsCount) cheat mod(s) flagged!" "#EF4444"
            foreach ($fm in $inst.FlaggedMods) {
                Add-CleanRow " - Flagged" "$($fm.FileName) ($($fm.Reason))" "#FBBF24"
            }
        } else {
            Add-CleanRow "Integrity" "All $($inst.TotalModsCount) mods passed integrity scan" "#34D399"
        }

        # Summary of All Other Discovered Instances on PC
        if ($Global:ReportData.AllInstances -and $Global:ReportData.AllInstances.Count -gt 1) {
            Add-CleanSectionHeader "ALL DISCOVERED CLIENTS & PROFILES ($($Global:ReportData.AllInstances.Count) TOTAL)"
            foreach ($other in $Global:ReportData.AllInstances) {
                $stColor = if ($other.FlaggedModsCount -gt 0) { "#EF4444" } else { "#34D399" }
                $stDesc = if ($other.FlaggedModsCount -gt 0) { "[!] $($other.FlaggedModsCount) CHEAT MODS | $($other.TotalModsCount) mods" } else { "Clean ($($other.TotalModsCount) mods)" }
                Add-CleanRow "[$($other.Launcher)]" "$($other.Profile) -> $stDesc" $stColor
            }
        }

        # Global Cheat & Suspicious Artifacts (Prefetch, BAM, and flagged files)
        Add-CleanSectionHeader "SYSTEM CHEAT & SUSPICIOUS ARTIFACTS"
        if ($script:cachedActualCheats.Count -gt 0) {
            $shownFiles = @()
            foreach ($c in $script:cachedActualCheats) {
                if ($c.File -notin $shownFiles) {
                    $shownFiles += $c.File
                    Add-CleanRow "File"     $c.File "#EF4444"
                    if ($c.Path) { Add-CleanRow "Location" $c.Path "#94A3B8" }
                    if ($c.Time) { Add-CleanRow "Activity" "Executed / Modified $c.Time" "#FBBF24" }
                }
            }
        } else {
            Add-CleanRow "Status" "Clean: No cheat files or blacklisted loaders detected on this PC." "#34D399"
        }
    }

    # Synchronize Active Instance across Results, Details, and Mods Views
    $script:isSyncingInstance = $false

    function Sync-SelectedInstance([int]$idx) {
        if ($script:isSyncingInstance) { return }
        if (-not $Global:ReportData.AllInstances -or $idx -lt 0 -or $idx -ge $Global:ReportData.AllInstances.Count) { return }

        $script:isSyncingInstance = $true
        try {
            $targetInst = $Global:ReportData.AllInstances[$idx]
            $Global:ReportData.LastPlayedInstance = $targetInst
            $Global:ReportData.ActiveInstanceMods = $targetInst.Mods

            # Sync Dropdown controls
            if ($cmbResultInstance.SelectedIndex -ne $idx) { $cmbResultInstance.SelectedIndex = $idx }
            if ($cmbDetailsInstance.SelectedIndex -ne $idx) { $cmbDetailsInstance.SelectedIndex = $idx }
            if ($cmbModsInstance.SelectedIndex -ne $idx) { $cmbModsInstance.SelectedIndex = $idx }

            # Update Results Card
            $txtResultTime.Text = if ($targetInst.LastPlayedTime) { "$($targetInst.LastPlayedTime)" } else { "Historical" }
            $txtResultClient.Text = "Client   : $($targetInst.Launcher)"
            $verDisplay = if ($targetInst.Version) { " ($($targetInst.Version))" } else { "" }
            $txtResultProfile.Text = "Profile  : $($targetInst.Profile)$verDisplay"
            if ($targetInst.ConnectedServers -and $targetInst.ConnectedServers.Count -gt 0) {
                $txtResultServer.Text = "Server   : $($targetInst.ConnectedServers -join ', ')"
            } else {
                $txtResultServer.Text = "Server   : Singleplayer / Unrecorded"
            }

            # Update Mods Button & View
            $btnMods.Content = "ALL MODS ($($targetInst.TotalModsCount))"
            $txtModsTitle.Text = "INSTALLED MODS ($($targetInst.TotalModsCount))"
            $txtModsSubtitle.Text = "[$($targetInst.Launcher)] $($targetInst.Profile)"
            $txtModsSummaryStats.Text = "$($targetInst.TotalModsCount) mods in $($targetInst.Profile)"
            if ($targetInst.FlaggedModsCount -gt 0) {
                $txtModsFlaggedCount.Text = "[!] $($targetInst.FlaggedModsCount) Flagged Suspicious"
                $txtModsFlaggedCount.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
            } else {
                $txtModsFlaggedCount.Text = "[OK] All Mods Clean"
                $txtModsFlaggedCount.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            }
            Render-ModsList -Filter $txtModSearch.Text.Trim()

            # Update Details Panel
            Render-DetailsForInstance -inst $targetInst
        } finally {
            $script:isSyncingInstance = $false
        }
    }

    # Hook ComboBox selection events
    $cmbResultInstance.Add_SelectionChanged({ Sync-SelectedInstance $cmbResultInstance.SelectedIndex })
    $cmbDetailsInstance.Add_SelectionChanged({ Sync-SelectedInstance $cmbDetailsInstance.SelectedIndex })
    $cmbModsInstance.Add_SelectionChanged({ Sync-SelectedInstance $cmbModsInstance.SelectedIndex })

    # Deep Scan Runner
    $btnScan.Add_Click({
        $script:isScanning = $true
        $window.Topmost = $true
        $window.Activate()
        $btnMin.Opacity = 0.3
        $btnClose.Opacity = 0.3
        $homeView.Visibility = [System.Windows.Visibility]::Collapsed
        $progressView.Visibility = [System.Windows.Visibility]::Visible
        $detailsContentPanel.Children.Clear()
        $modsListPanel.Children.Clear()

        try {
            # Reset state
        $Global:ReportData.Scorecard.Flags = 0
        $Global:ReportData.Scorecard.Warnings = 0
        $Global:ReportData.Scorecard.Clean = 0
        $Global:ReportData.Scorecard.Info = 0
        $Global:ReportData.CheatClients = @()
        $Global:ReportData.LegitClients = @()
        $Global:ReportData.ActiveInstanceMods = @()
        $Global:ReportData.AllInstances = @()

        # Step 1: Memory & Active Process Inspection (0% to 15%)
        for ($pct = 1; $pct -le 15; $pct++) {
            $scanProgress.Value = $pct
            if ($txtProgressPercent) { $txtProgressPercent.Text = "$pct%" }
            $txtProgressStatus.Text = "Scanning active memory & running processes... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 30
        }
        try { Scan-JavaProcesses } catch { Write-Host "Process scan error: $_" }
        Pump-WpfEvents

        # Step 2: Minecraft Instances, Versions & Deep Mods Inspection (15% to 35%)
        $scanProgress.Value = 16
        if ($txtProgressPercent) { $txtProgressPercent.Text = "16%" }
        $txtProgressStatus.Text = "Deep scanning all Minecraft clients & instances... - 16%"
        Pump-WpfEvents
        $instCallback = {
            param([int]$p, [string]$msg)
            $scanProgress.Value = $p
            if ($txtProgressPercent) { $txtProgressPercent.Text = "$p%" }
            $txtProgressStatus.Text = "$msg - $p%"
            Pump-WpfEvents
        }
        try { Scan-LastPlayedInstance -ProgressCallback $instCallback } catch { Write-Host "Instance scan error: $_" }
        $scanProgress.Value = 35
        if ($txtProgressPercent) { $txtProgressPercent.Text = "35%" }
        $txtProgressStatus.Text = "Minecraft instances & mods analyzed - 35%"
        Pump-WpfEvents

        # Step 3: Windows Prefetch & BAM Execution History (35% to 60%)
        for ($pct = 36; $pct -le 60; $pct++) {
            $scanProgress.Value = $pct
            if ($txtProgressPercent) { $txtProgressPercent.Text = "$pct%" }
            $txtProgressStatus.Text = "Scanning Windows Prefetch & BAM kernel timestamps... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 25
        }
        try { Scan-PrefetchTraces -Hours $HoursPrefetch } catch { Write-Host "Prefetch scan error: $_" }
        try { Scan-BAMRegistry -Hours $HoursBAM } catch { Write-Host "BAM scan error: $_" }
        Pump-WpfEvents

        # Step 4: UserAssist & MuiCache Application History (60% to 80%)
        for ($pct = 61; $pct -le 80; $pct++) {
            $scanProgress.Value = $pct
            if ($txtProgressPercent) { $txtProgressPercent.Text = "$pct%" }
            $txtProgressStatus.Text = "Auditing UserAssist ROT13 & execution traces... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 25
        }
        try { Scan-UserAssist } catch { Write-Host "UserAssist scan error: $_" }
        Pump-WpfEvents

        # Step 5: File System, Temp drops & Anti-Forensics (80% to 95%)
        for ($pct = 81; $pct -le 95; $pct++) {
            $scanProgress.Value = $pct
            if ($txtProgressPercent) { $txtProgressPercent.Text = "$pct%" }
            $txtProgressStatus.Text = "Auditing file systems, temp drops & anti-forensics... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 25
        }
        try { Scan-FileSystem -Hours $HoursFiles } catch { Write-Host "FileSystem scan error: $_" }
        try { Scan-USBStorage } catch { Write-Host "USBStorage scan error: $_" }
        Pump-WpfEvents

        # Step 6: Finalizing & Compiling Report (95% to 100%)
        for ($pct = 96; $pct -le 100; $pct++) {
            $scanProgress.Value = $pct
            if ($txtProgressPercent) { $txtProgressPercent.Text = "$pct%" }
            $txtProgressStatus.Text = "Finalizing forensic report & scorecard... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 25
        }

        # Collect all system-level cheat detections (Prefetch, BAM, FileSystem, etc.)
        $actualCheats = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($f in $Global:Findings) {
            if ($f.Level -eq "FLAG") {
                $msg = "$($f.Message) $($f.Detail)"
                if ($msg -like "*essential*" -or $msg -like "*theseus*" -or $msg -like "*imgui*" -or $msg -like "*jna*" -or $msg -like "*LOG WAS WIPED*") {
                    continue
                }

                $fileName = ""
                $filePath = ""
                $actionTime = ""

                if ($f.Detail -match "([^|\r\n]+)\s*\(Executed:\s*([^)]+)\)\s*\|\s*(.*)") {
                    $fileName = $matches[1].Trim()
                    $actionTime = $matches[2].Trim()
                    $filePath = $matches[3].Trim()
                } elseif ($f.Detail -match "([^|\r\n]+)\s*\(Last Executed:\s*([^)]+)\)") {
                    $fileName = $matches[1].Trim()
                    $actionTime = $matches[2].Trim()
                } elseif ($f.Detail -match "([^(\r\n]+)\s*\(Matches:\s*([^)]+)\)") {
                    $fileName = $matches[1].Trim()
                } else {
                    $fileName = $f.Detail
                }

                if ($fileName -like "*.exe") {
                    $fileName = [System.IO.Path]::GetFileName($fileName)
                }

                $actualCheats.Add([PSCustomObject]@{
                    File   = $fileName
                    Path   = $filePath
                    Time   = $actionTime
                    Reason = $f.Message
                })
            }
        }

        # Include flagged mods across ALL instances so no cheat mod is ever missed
        if ($Global:ReportData.AllInstances) {
            foreach ($inst in $Global:ReportData.AllInstances) {
                if ($inst.FlaggedMods) {
                    foreach ($fm in $inst.FlaggedMods) {
                        $actualCheats.Add([PSCustomObject]@{
                            File   = $fm.FileName
                            Path   = $fm.FullPath
                            Time   = $fm.LastWriteTime
                            Reason = "[$($inst.Launcher) / $($inst.Profile)] $($fm.Reason)"
                        })
                    }
                }
            }
        }

        $script:cachedActualCheats = $actualCheats

        # Populate Instance Selector Dropdowns
        $script:isSyncingInstance = $true
        $cmbResultInstance.Items.Clear()
        $cmbDetailsInstance.Items.Clear()
        $cmbModsInstance.Items.Clear()

        $allInst = $Global:ReportData.AllInstances
        if ($allInst -and $allInst.Count -gt 0) {
            foreach ($inst in $allInst) {
                $statusTag = if ($inst.FlaggedModsCount -gt 0) {
                    " [!] $($inst.FlaggedModsCount) CHEAT MODS"
                } elseif ($inst.TotalModsCount -gt 0) {
                    " ($($inst.TotalModsCount) mods)"
                } else {
                    " (0 mods)"
                }

                $displayText = "[$($inst.Launcher)] $($inst.Profile)$statusTag"
                $cmbResultInstance.Items.Add($displayText) | Out-Null
                $cmbDetailsInstance.Items.Add($displayText) | Out-Null
                $cmbModsInstance.Items.Add($displayText) | Out-Null
            }
            $script:isSyncingInstance = $false
            Sync-SelectedInstance 0
        } else {
            $script:isSyncingInstance = $false
            $txtResultTime.Text = "No Instance Found"
            $txtResultClient.Text = "Client   : No Minecraft installation detected"
            $txtResultProfile.Text = "Profile  : N/A"
            $txtResultServer.Text = "Server   : N/A"
            $btnMods.Content = "ALL MODS (0)"
        }

        # Main Screen Cheat Badge Status
        if ($actualCheats.Count -gt 0) {
            $txtResultTitle.Text = "Cheats Detected"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            $txtResultSubtitle.Text = "$($actualCheats.Count) suspicious or cheat client artifacts found"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
            $txtDetectionsBadge.Text = "[!] SUSPICIOUS CLIENT / CHEATS DETECTED"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            $detectionBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#991B1B")

            $uniqueFiles = $actualCheats | ForEach-Object { $_.File } | Select-Object -Unique
            $txtCheatList.Text = "Flagged: " + ($uniqueFiles -join ", ")
            $txtCheatList.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $txtResultTitle.Text = "Scan Complete"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
            $txtResultSubtitle.Text = "All deep forensic tests concluded"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtDetectionsBadge.Text = "[OK] No Cheats or Suspicious Clients Detected"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $detectionBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#065F46")
            $txtCheatList.Visibility = [System.Windows.Visibility]::Collapsed
        }

        $txtSummaryStats.Text = "$($actualCheats.Count) Cheats Flagged | $($allInst.Count) Clients/Instances Discovered"
        } catch {
            Write-Host "Scan encountered an error: $_" -ForegroundColor Red
            if ($Global:Findings.Count -eq 0) {
                Write-Alert -Level "WARN" -Message "Scan encountered an exception: $($_.Exception.Message)"
            }
        } finally {
            $script:isScanning = $false
            $btnMin.Opacity = 1.0
            $btnClose.Opacity = 1.0
            # Show Results View
            $progressView.Visibility = [System.Windows.Visibility]::Collapsed
            $resultsView.Visibility = [System.Windows.Visibility]::Visible
            Pump-WpfEvents
        }
    })

    # Export JSON Handler
    $btnExportJson.Add_Click({
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $filename = "Gricko_SS_Report_${timestamp}.json"
        $savePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), $filename)
        try {
            $Global:ReportData | ConvertTo-Json -Depth 6 | Set-Content -Path $savePath -Encoding UTF8
            [System.Windows.MessageBox]::Show("Forensic report exported to Desktop:`n$savePath", "Gricko SS Tool", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            $msg = $_.Exception.Message
            [System.Windows.MessageBox]::Show("Failed to export report: $msg", "Export Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    $window.ShowDialog() | Out-Null
}